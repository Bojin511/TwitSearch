#import "SearchResultsViewController.h"
#import "WebViewController.h"
#import "TweetTableCell.h"

@interface SearchResultsViewController ()
@property (nonatomic, retain) NSArray *tweets;
@property (nonatomic, retain) NSOperationQueue *operationQueue;
@end

@interface SearchResultsViewController (PrivateMethods)
- (IBAction)refreshTweets:(id)sender;
- (void)loadTweetsFromSearchTerm;
@end

@interface SearchResultsViewController (CachingHelpers)
- (NSString *)pathForCachedImageForTwitterUserID:(NSString *)userID;
- (UIImage *)cachedImageForTwitterUserID:(NSString *)userID;
- (void)downloadAndCacheProfileImageURL:(NSURL *)URL forTwitterUserID:(NSString *)userID;
@end

@implementation SearchResultsViewController

#pragma mark View lifecycle
- (void)viewDidLoad
{
  [super viewDidLoad];

  // Create the operation queue
  if (self.operationQueue == nil) {
    self.operationQueue = [[NSOperationQueue alloc] init];
  }

  // If no trend information was supplied, log an error.
  if (self.searchTerm == nil || [self.searchTerm length] <= 0)
    NSLog(@"Error: No search term was supplied");

  // Load the tweets into the table view on a background thread
  __weak SearchResultsViewController *weakSelf = self;
  [self.operationQueue addOperationWithBlock:^{
    [weakSelf loadTweetsFromSearchTerm];
  }];

  // Set the navigation bar title
  self.title = self.searchTerm;
}

#pragma mark Table view data source
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
  if (self.tweets) {
    // Data is loaded, show all tweets
    return [self.tweets count];
  } else {
    // Otherwise return a single cell for the loading indicator
    return 1;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (self.tweets != nil) {
    // Data is loaded, cells should load tweet data
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TweetCell"];

    // Get the current tweet and set the text of the cell
    NSDictionary *tweet = [self.tweets objectAtIndex:indexPath.row];
    cell.textLabel.text = [tweet valueForKey:@"from_user"];
    cell.detailTextLabel.text = [tweet valueForKey:@"text"];

    // Attempt to load the avatar into the image view
    NSString *userID = [tweet valueForKey:@"id_str"];
    UIImage *userImage = [self cachedImageForTwitterUserID:userID];
    if (userImage) {
      cell.imageView.image = userImage;
    } else {
      cell.imageView.image = [UIImage imageNamed:@"Placeholder.png"];
      
      // Kick off the download of the image from twitter
      NSString *imageURLString = [tweet valueForKey:@"profile_image_url"];
      NSURL *URL = [NSURL URLWithString:imageURLString];
      [self downloadAndCacheProfileImageURL:URL forTwitterUserID:userID];
    }
    return cell;
  } else {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LoadingCell"];
    return cell;
  }
}

#pragma mark Table view delegate
- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSDictionary *tweet = [self.tweets objectAtIndex:indexPath.row];
  return [TweetTableCell heightForTableRowIn:tableView withTweetDictionary:tweet];
}

#pragma mark Segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
  // Derive the URL for the selected tweet
  NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
  NSDictionary *selectedTweet = [self.tweets objectAtIndex:indexPath.row];
  static NSString *twitterLocation = @"http://twitter.com";
  NSString *tweetLocation = [NSString stringWithFormat:@"%@/#!/%@/status/%@", twitterLocation, [selectedTweet valueForKey:@"from_user"], [selectedTweet valueForKey:@"id_str"]];

  // Pass the URL to the web view controller
  WebViewController *controller = segue.destinationViewController;
  controller.URL = [NSURL URLWithString:tweetLocation];
}

#pragma mark Actions
- (IBAction)refreshTweets:(id)sender
{
  // Load the tweets into the table view on a background thread
  __weak SearchResultsViewController *weakSelf = self;
  [self.operationQueue addOperationWithBlock:^{
    [weakSelf loadTweetsFromSearchTerm];
  }];

  // Scroll the table view to the top
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
  [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark Loading tweets
- (void)loadTweetsFromSearchTerm
{
  // Set the status bar network indicator spinning on the main thread
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  }];

  // Prepare the URL for fetching
  NSString *encodedTerm = [self.searchTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  NSString *searchLocation = [NSString stringWithFormat:@"http://search.twitter.com/search.json?q=%@", encodedTerm];
  NSURL *searchURL = [NSURL URLWithString:searchLocation];

  // Download and parse the JSON
  NSData *JSONData = [[NSData alloc] initWithContentsOfURL:searchURL];
  if ([JSONData length] > 0) {
    // If data was returned, parse it as JSON
    NSError *error = nil;
    NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
    if (!JSONDictionary) {
      NSLog(@"JSON parsing failed: %@", error);
    }

    // Keep a copy of the search result tweets
    self.tweets = [JSONDictionary valueForKey:@"results"];

    // Make the table view refresh on the main thread
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [self.tableView reloadData];
    }];
  } else {
    // Otherwise show an error message on the main thread
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to fetch tweets for this search term. Please make sure you are connected to a network." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
    }];
  }

  // Set the status bar network indicator spinning on the main thread
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  }];
}

- (UIImage *)cachedImageForTwitterUserID:(NSString *)userID
{
  NSString *imagePath = [self pathForCachedImageForTwitterUserID:userID];
  return [UIImage imageWithContentsOfFile:imagePath];
}

- (void)downloadAndCacheProfileImageURL:(NSURL *)URL forTwitterUserID:(NSString *)userID
{
  __weak SearchResultsViewController *weakSelf = self;
  [self.operationQueue addOperationWithBlock:^{
    NSData *imageData = [NSData dataWithContentsOfURL:URL];
    if (imageData) {
      // Write the image file to disk
      NSString *imagePath = [weakSelf pathForCachedImageForTwitterUserID:userID];
      [imageData writeToFile:imagePath atomically:YES];

      // Let the table view know to reload
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
      }];
    }
  }];
}

- (NSString *)pathForCachedImageForTwitterUserID:(NSString *)userID
{
  NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
  NSString *imageFileName = [NSString stringWithFormat:@"%@.png", userID];
  return [cachesPath stringByAppendingPathComponent:imageFileName];
}

@end
