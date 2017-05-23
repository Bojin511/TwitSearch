#import "SearchInputViewController.h"
#import "SearchResultsViewController.h"

@interface SearchInputViewController ()
@property (strong, nonatomic) NSString *searchTerm;
@property (strong, nonatomic) IBOutlet UITextField *searchTextField;
@end

@implementation SearchInputViewController

#pragma mark View lifecycle
- (void)viewDidLoad
{
  [super viewDidLoad];

  // Restore any previously saved search text
  self.searchTextField.text = self.searchTerm;

  // Focus the text field and show the keyboard
  [self.searchTextField becomeFirstResponder];
}

#pragma mark Segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"searchTwitterSegue"]) {
    // Pass the search term to the results view controller so it can be queried
    SearchResultsViewController *controller = segue.destinationViewController;
    controller.searchTerm = self.searchTerm;
  }
}

#pragma mark UITextField delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  // Take the search term from the text field and save it
  self.searchTerm = self.searchTextField.text;

  // Check that some text has been entered
  if ([self.searchTerm length] <= 0) return NO;

  // Segue to the search results view controller
  // Note that data should still be transferred in prepareForSegue:sender.
  [self performSegueWithIdentifier:@"searchTwitterSegue" sender:self];

  // Allow the text field to return
  return YES;
}

@end
