#import "TweetTableCell.h"

@implementation TweetTableCell

- (void)awakeFromNib
{
  self.textLabel.font = [TweetTableCell boldCellFont];
  self.textLabel.lineBreakMode = UILineBreakModeWordWrap;
  self.textLabel.numberOfLines = NSIntegerMax;

  self.detailTextLabel.font = [TweetTableCell cellFont];
  self.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
  self.detailTextLabel.numberOfLines = NSIntegerMax;
  self.detailTextLabel.textColor = [UIColor colorWithWhite:0.2 alpha:1];
}

+ (UIFont *)cellFont
{
  return [UIFont systemFontOfSize:15];
}

+ (UIFont *)boldCellFont
{
  return [UIFont boldSystemFontOfSize:16];
}

+ (CGFloat)heightForTableRowIn:(UITableView *)tableView
           withTweetDictionary:(NSDictionary *)tweetData
{
  // Get the text which will be displayed in this cell
  NSString *authorText = [tweetData valueForKey:@"from_user"];
  NSString *tweetText = [tweetData valueForKey:@"text"];

  // Calculate the table view constraint from the cell width
  CGSize constraint = CGSizeMake(220, CGFLOAT_MAX);

  // Calculate how much space is needed to display the tweet and author text
  CGFloat authorHeight = [authorText sizeWithFont:[TweetTableCell boldCellFont] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap].height;
  CGFloat tweetHeight = [tweetText sizeWithFont:[TweetTableCell cellFont] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap].height;

  // Never return a cell height less than the standard 44 pixels
  return MAX(44, tweetHeight + authorHeight + 10);
}

@end
