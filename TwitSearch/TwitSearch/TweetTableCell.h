@interface TweetTableCell : UITableViewCell

+ (UIFont *)cellFont;
+ (UIFont *)boldCellFont;

+ (CGFloat)heightForTableRowIn:(UITableView *)tableView
           withTweetDictionary:(NSDictionary *)tweetData;

@end
