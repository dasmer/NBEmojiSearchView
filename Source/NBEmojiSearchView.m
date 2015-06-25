#import "NBEmojiManager.h"
#import "NBEmojiSearchResultTableViewCell.h"
#import "NBEmojiSearchView.h"

@interface NBEmojiSearchView () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIView *dividerView;

@property (nonatomic, strong) id<UITextFieldDelegate> textFieldDelegate;
@property (nonatomic, strong) NBEmojiManager *manager;
@property (nonatomic) NSRange currentSearchRange;

@end

@implementation NBEmojiSearchView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addSubview:self.tableView];
        [self addSubview:self.dividerView];
        self.rowHeight = 44.0;
        self.alpha = 0.0;
        self.font = [UIFont systemFontOfSize:17.0];
        self.textColor = [UIColor darkTextColor];
    }
    return self;
}

#pragma mark - Public

- (void)searchWithText:(NSString *)searchText
{
    [self.manager searchWithText:searchText];
    if ([self.manager numberOfSearchResults] == 0) {
        [self disappear];
    } else {
        [self.tableView reloadData];
        [self appear];
    }
}

- (void)installOnTextField:(UITextField *)textField
{
    self.textFieldDelegate = textField.delegate;
    self.textField = textField;
    self.textField.delegate = self;
}

#pragma mark - Property

- (NBEmojiManager *)manager
{
    if (!_manager) {
        _manager = [[NBEmojiManager alloc] init];
    }
    return _manager;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.frame = self.bounds;
        _tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                       UIViewAutoresizingFlexibleHeight);
        [_tableView registerClass:[NBEmojiSearchResultTableViewCell class]
           forCellReuseIdentifier:NSStringFromClass([NBEmojiSearchResultTableViewCell class])];
        _tableView.showsVerticalScrollIndicator = NO;
    }
    return _tableView;
}

- (UIView *)dividerView
{
    if (!_dividerView) {
        _dividerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.5)];
        _dividerView.backgroundColor = [UIColor colorWithWhite:205.0/255.0 alpha:1.0];
        _dividerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    return _dividerView;
}

#pragma mark - View

- (void)appear
{
    if ([self.delegate respondsToSelector:@selector(emojiSearchViewWillAppear:)]) {
        [self.delegate emojiSearchViewWillAppear:self];
    }
    self.alpha = 1.0;
    if ([self.delegate respondsToSelector:@selector(emojiSearchViewDidAppear:)]) {
        [self.delegate emojiSearchViewDidAppear:self];
    }
}

- (void)disappear
{
    if ([self.delegate respondsToSelector:@selector(emojiSearchViewWillDisappear:)]) {
        [self.delegate emojiSearchViewWillAppear:self];
    }
    self.alpha = 0.0;
    if ([self.delegate respondsToSelector:@selector(emojiSearchViewDidDisappear:)]) {
        [self.delegate emojiSearchViewDidAppear:self];
    }
    [self.manager clear];
    self.currentSearchRange = NSMakeRange(0, 0);
}

#pragma mark - UITableView(DataSource|Delegate)

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.manager numberOfSearchResults];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = NSStringFromClass([NBEmojiSearchResultTableViewCell class]);
    NBEmojiSearchResultTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier
                                                                                  forIndexPath:indexPath];
    cell.emoji = [self.manager emojiAtIndex:indexPath.row];
    cell.textLabel.font = self.font;
    cell.textLabel.textColor = self.textColor;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *replacementString = [NSString stringWithFormat:@"%@ ", [self.manager emojiAtIndex:indexPath.row].emoji];
    NSRange extendedRange = NSMakeRange(self.currentSearchRange.location - 1, self.currentSearchRange.length + 1);
    self.textField.text = [self.textField.text stringByReplacingCharactersInRange:extendedRange
                                                                       withString:replacementString];
    [self disappear];
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.manager clear];
    [self.tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.rowHeight;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.headerTitle;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([self.textFieldDelegate respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
        [self.textFieldDelegate textFieldDidBeginEditing:textField];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([self.textFieldDelegate respondsToSelector:@selector(textFieldDidEndEditing:)]) {
        [self.textFieldDelegate textFieldDidBeginEditing:textField];
    }
}

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSInteger searchLength = range.location + string.length;
    NSRange colonRange = [newString rangeOfString:@":" options:NSBackwardsSearch range:NSMakeRange(0, searchLength)];
    NSRange spaceRange = [newString rangeOfString:@" " options:NSBackwardsSearch range:NSMakeRange(0, searchLength)];
    if (colonRange.location != NSNotFound && (spaceRange.location == NSNotFound ||  colonRange.location > spaceRange.location)) {
        [self searchWithColonLocation:colonRange.location string:newString];
    } else {
        [self disappear];
    }

    if ([self.textFieldDelegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        return [self.textFieldDelegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
    } else {
        return YES;
    }
}

- (void)searchWithColonLocation:(NSUInteger)colonLocation string:(NSString *)string
{
    NSRange searchRange = NSMakeRange(colonLocation + 1, string.length - colonLocation - 1);
    NSRange spaceRange = [string rangeOfString:@" " options:NSCaseInsensitiveSearch range:searchRange];
    NSString *searchText;
    if (spaceRange.location == NSNotFound) {
        searchText = [string substringFromIndex:colonLocation + 1];
    } else {
        searchText = [string substringWithRange:NSMakeRange(colonLocation + 1, spaceRange.location - colonLocation - 1)];
    }
    self.currentSearchRange = NSMakeRange(colonLocation + 1, searchText.length);
    [self searchWithText:searchText];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if ([self.textFieldDelegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]) {
        return [self.textFieldDelegate textFieldShouldBeginEditing:textField];
    } else {
        return YES;
    }
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if ([self.textFieldDelegate respondsToSelector:@selector(textFieldShouldClear:)]) {
        return [self.textFieldDelegate textFieldShouldClear:textField];
    } else {
        return YES;
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if ([self.textFieldDelegate respondsToSelector:@selector(textFieldShouldEndEditing:)]) {
        return [self.textFieldDelegate textFieldShouldEndEditing:textField];
    } else {
        return YES;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self.textFieldDelegate respondsToSelector:@selector(textFieldShouldReturn:)]) {
        return [self.textFieldDelegate textFieldShouldReturn:textField];
    } else {
        return YES;
    }
}

@end
