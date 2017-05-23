#import "WebViewController.h"

@interface WebViewController ()
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation WebViewController

#pragma mark View lifecycle
- (void)viewDidLoad
{
  [super viewDidLoad];

  // If no URL was supplied, log an error.
  if (self.URL == nil)
    NSLog(@"Error: No URL was specified");

  // Load the URL into the web view
  NSURLRequest *request = [NSURLRequest requestWithURL:self.URL];
  [self.webView loadRequest:request];
}

#pragma mark Web view delegate
- (void)webViewDidStartLoad:(UIWebView *)webView
{
  // Set the status bar network indicator spinning
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
  // Stop the status bar spinner
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end
