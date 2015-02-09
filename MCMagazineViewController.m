//
//  MCMagazineViewController.m
//  Monocept
//
//  Created by Jayaganesh G. on 2/9/14.
//  Copyright (c) 2014 Monocept. All rights reserved.
//

#import "MCMagazineViewController.h"
#import "MCMagazineViewController.h"
#import "MCWebViewController.h"
#import "MCActivityProvider.h"
#import "MCNewProductTableViewCell.h"
#import "MCActivityProvider.h"
#import "MCProductItemDetailViewCell.h"
#import "MCSettingViewController.h"
#import "MCSearchViewController.h"
#import "MCConstants.h"
#import "SFTwoTapBuyViewController.h"
#import "SFArticleDetailFooterTableViewCell.h"
#import "SFFacbookActivityIOS8.h"
#import "SFFacbookActivityIOS7.h"
#import "PBSafariActivity.h"
#import "PBSafariActivity.h"

static const NSTimeInterval kSFRefreshInterval = 86400; // seconds

@interface MCMagazineViewController ()

{
    NSString * _trending;
}
@property (assign, nonatomic) BOOL isReadMoreTapped;
@property (strong, nonatomic) NSArray *hashTagList;
@property (nonatomic) BOOL shouldSetDelegateNilForDescriptionCell;
@property (nonatomic) BOOL shouldSetDelegateNilForFooterCell;


@end

@implementation MCMagazineViewController

static NSString *cellProductDetailsCellIdentifier           = @"NewProductDetailsCell";
static NSString *cellProductImageCellIdentifier             = @"NewProductImageCell";
static NSString *cellArticleDescriptionCellIdentifier       = @"articleDescriptionCell";
static NSString *kCellArticleDetailsFooterCellIdentifier    = @"articleDetailsFooterCell";


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Mix panel tracking
    _trending = [MCMuluApiManager manager].trending ? @"YES" : @"NO";
    
    // Do any additional setup after loading the view from its nib.
    
    // White background color to view
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.isReadMoreTapped = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // For article if there is no hashtag, server team is setting value as "NA".
    if (![self.currentArticle.hashTags isEqualToString:@"NA"]) {
        self.hashTagList = [self.currentArticle.hashTags componentsSeparatedByString:@","];
        
    }
    
    
    // **************************************************** TABLEVIEW  SETUP ************************************************
    /*
     IMPORTANT :
     
     Logic for displayint the product details in tableview.
     MCNewProductTableViewCell,MCProductItemDetailViewCell are used for displaying the product image and title,excerpt message.
     
     MCNewProductTableViewCell :
     a. This cell will display the image of product and love/share button,productNumber as well.
     MCProductItemDetailViewCell :
     a. This cell will display the title of product,price and excerpt message.
     
     If productList array is 20 multiply by 2 = 40, So tableView will create 40 rows to display the details of product.
     First row is for productImage with help of MCNewProductTableViewCell class.
     Second row is for title,price and excerpt message with help of MCProductItemDetailViewCell class.
     */
    
    [self.tableView setSeparatorColor:[UIColor MCBorderColor]];
    if(CGRectGetHeight([UIScreen mainScreen].bounds) <= 480) {
        [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 90, 0)];
    }
    [self.tableView registerNib:[UINib nibWithNibName:@"MCProductItemDetailViewCell" bundle:nil] forCellReuseIdentifier:cellProductImageCellIdentifier];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"MCArticleDescriptionCell" bundle:nil] forCellReuseIdentifier:cellArticleDescriptionCellIdentifier];
    
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SFArticleDetailFooterTableViewCell" bundle:nil] forCellReuseIdentifier:kCellArticleDetailsFooterCellIdentifier];
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    // **********************************************************************************************************************
    
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    
    // update the topBarView with new image.
    [self updateTopBarView];
    
    // Scroll the tableview to selected indexPath,tapping on products from publisher page.
    // Don't scroll the tableView for the first products.
    if (self.scrollIndexPath.row > 1) {
        [self.tableView scrollToRowAtIndexPath:self.scrollIndexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
        // 3.5 inch screen product is not showing from begining,adjusting the contentOffset of tableview will make the starting product to be visible on the screen.
        if (CGRectGetHeight([UIScreen mainScreen].bounds) <= 480) {
            CGPoint tableViewContentOffSet = self.tableView.contentOffset;
            tableViewContentOffSet.y -= 100.0f;
            self.tableView.contentOffset = tableViewContentOffSet;
        }
    }
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    // Set back to zero indexpath to the scrollIndexPath on viewDisappear.
    self.scrollIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc {}

- (IBAction)doneButtonTapped:(id)sender
{
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark General Methods

- (void)updateTopBarView
{
    
    self.photoCreditLabel.text = self.currentArticle.aPhotoCredit;
    //-------------------------------Load the images------------------------
    // If we got the article image use it otherwise use the product image as a background image;
    [self.footerBackgroundImage sd_setImageWithURL:[NSURL URLWithString:self.currentArticle.imageURL] placeholderImage:[UIImage imageNamed:@"banner.png"] options:SDWebImageProgressiveDownload];
    //---------------------------------------------------------------------------
    
}

- (void)showSearchResultPageWithHasTag:(NSString *)hashTag {
    
    /**
     
     As per the discussion we are not going to include @ with topic tags.
     
     */
    
    /**
     ** self.isPushedFromMagazineViewController
     
     * When searchViewController as a rootViewController If user reaches the magazine page and choosing any product or post will take the user to MCArticleViewController again.
     * Tapping on hashTag button in article page should not open the one more searchViewController instead of popToRootViewController(which is searchViewController).
     
     ** self.isPushedFromSearchViewController
     
     *  In searchViewController user can tap any post or product which will take user to articlePage. If user tap on hashTag dont bring another searchViewController instead of pop it searcViewController.
     
     */
    for (UIViewController *viewController in [self.navigationController viewControllers]) {
        if ([viewController isKindOfClass:[MCSearchViewController class]]){
            if (self.isPushedFromMagazineViewController || self.isPushedFromSearchViewController) {
                [self.navigationController popToRootViewControllerAnimated:YES];
                NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:hashTag,@"hashTag", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:kGetSearchResultForHasTagNotification object:self userInfo:userInfo];
                return;
            }
        }
    }
    
    /**
     
     If searchViewController not exist in navigation stack, present it on screen.
     
     */
    
    MCSearchViewController *searchViewController  = [MCSearchViewController new];
    searchViewController.shouldSearchForHashTag = YES;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:searchViewController];
    
    [navigationController setNavigationBarHidden:YES];
    [self.navigationController presentViewController:navigationController animated:YES completion:^{
        [searchViewController getResultForSearchString:hashTag];
        searchViewController.searchBar.text = hashTag;
    }];
    
}


- (void)loadNextArticle:(BOOL)isNext {
    
    
    if (isNext) {
        self.currentArticleIndex += 1;
        
    } else {
        
        self.currentArticleIndex -= 1;
    }
    
    
    MCArticle* article = (MCArticle*)[self.articleList objectAtIndex:self.currentArticleIndex];
    self.currentArticle = article;
    [MCMuluApiManager manager].currentArticle = article;
    
    // For article if there is no hashtag, server team is setting value as "NA".
    if (![self.currentArticle.hashTags isEqualToString:@"NA"]) {
        self.hashTagList = [self.currentArticle.hashTags componentsSeparatedByString:@","];
        
    } else {
        self.hashTagList = nil;
    }
    
    
    self.shouldSetDelegateNilForDescriptionCell = YES;
    self.shouldSetDelegateNilForFooterCell = YES;
    self.isReadMoreTapped = NO;
    [self updateTopBarView];
    
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointMake(0, 0)];
}

#pragma mark TableView DataSources


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return  1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    
    CGFloat height = 0.0f;
    
    // Cell 0 is represent the article title,publisher name and article description
    if(indexPath.row == 0) {
        
        // calculate the height of article title
        height = [self.currentArticle.title.uppercaseString boundingRectWithSize:CGSizeMake(290.0f,MAXFLOAT)
                                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                                      attributes:@{NSFontAttributeName : [MCFontManager GothamHTFBoldCondensedFontwithSize:30.0f]}
                                                                         context:nil].size.height ;
        CGFloat topMargin       = 5.0f;
        CGFloat tagYourFriends  = 40.0f;
        CGFloat bottomMargin    = 10.0f;
        CGFloat pubLabelHeight  = 42.0f;
        CGFloat padding         = 5.0f;
        CGFloat aDescriptionLebelHeight = [self getArticleDiscriptionTextHeight:self.currentArticle.aDescription] + padding;
        height = topMargin + ceilf(height) + topMargin + pubLabelHeight + bottomMargin + aDescriptionLebelHeight + tagYourFriends;
        
        // If article contains topic tag include the height for cell
        if (self.hashTagList.count > 0)
        {
            height += [self heightForArticleTopicTagForDescripitionCell];
        }
        
        return height;
    }
    
    /*
     For example -  1&2 row get the productDetails form index 1 of array.Same logic for other rows as well 2&3 will get it form index 2.
     
     But here logic changes first  index are now filled from article .
     So we need to reduce the indexPath.Row by 1 so that we will get correct data
     */
    
    // If there is no product just display the generic message with one cell.
    if(self.currentArticle.productList == 0)
        return 70.0f;
    
    else {
        
        // Display the share option and topic tags with more details in last cell.
        NSInteger   lastRowIndex                = (self.currentArticle.productList.count * 2) + 2;
        CGFloat     defaultHeightOfFooterCell   = 40.0f;
        CGFloat     extraSpaceForOtherOptions   = 55.0f;
        
        if (lastRowIndex == (indexPath.row + 1))
        {
            
            if (self.hashTagList.count > 0)
            {
                
                return ([self heightForArticleTopicTagForFooterCell] + extraSpaceForOtherOptions);
            }
            
            return defaultHeightOfFooterCell;
        }
        
        
        NSInteger index = indexPath.row - 1;
        self.currentProduct = [self.currentArticle.productList objectAtIndex:index / 2];
        
        if(index % 2 == 0) { // If indexPath.row % 2 isEqual to 0 means even number rows. or not equal to 0 means odd number rows.
            return  265;
            
        } else if (index % 2 != 0) {
            
            if (self.currentProduct.excerpt.length > 0) {
                
                height = [self.currentProduct.name boundingRectWithSize:CGSizeMake(300.0f,MAXFLOAT)
                                                                options:NSStringDrawingUsesLineFragmentOrigin
                                                             attributes:@{NSFontAttributeName : [MCFontManager GothamHTFBoldCondensedFontwithSize:24.0f]}
                                                                context:nil].size.height ;
                
                height += [self.currentProduct.excerpt boundingRectWithSize:CGSizeMake(252.0f,MAXFLOAT)
                                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                                 attributes:@{NSFontAttributeName : [MCFontManager FrutigerRomanFontwithSize:13.0f]}
                                                                    context:nil].size.height;
                
                return height + 90.0f;
                
            } else {
                height = [self.currentProduct.name boundingRectWithSize:CGSizeMake(300.0f,MAXFLOAT)
                                                                options:NSStringDrawingUsesLineFragmentOrigin
                                                             attributes:@{NSFontAttributeName : [MCFontManager GothamHTFBoldCondensedFontwithSize:24.0f]}
                                                                context:nil].size.height ;
                
                return height + 80;
                
            }
        }
        
    }
    return 0.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = self.currentArticle.productList.count;
    NSInteger extraRows = 2; // 1. Show article name & details & 2. Table view footer.
    return count > 0  ? ((count * 2) + extraRows) : extraRows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCNewProductTableViewCell               * productDetailsCell = nil;
    MCProductItemDetailViewCell             * productImageViewCell = nil;
    MCArticleDescriptionCell                * articleDescriptionCell = nil;
    SFArticleDetailFooterTableViewCell      * articleDetailFooterCell =  nil;
    // Create article description cell
    
    if(indexPath.row == 0)
    {
        articleDescriptionCell = (MCArticleDescriptionCell*)[tableView dequeueReusableCellWithIdentifier:cellArticleDescriptionCellIdentifier forIndexPath:indexPath];
    
    
        if (articleDescriptionCell.delegate == nil) {
            
            articleDescriptionCell.delegate = (id)self;
            articleDescriptionCell.hashTagString =  self.currentArticle.hashTags;
            articleDescriptionCell.hyperLinkArrayList = self.hashTagList;
            [articleDescriptionCell createHyperLinkButtons:self.hashTagList];
        }
        
        articleDescriptionCell.selectionStyle = UITableViewCellSelectionStyleNone;
        articleDescriptionCell.articleTitleLabel.text = self.currentArticle.title.uppercaseString;
        [articleDescriptionCell setPublisherImageViewWithGUID:self.currentArticle.publisherGUID];
        [articleDescriptionCell setPublisherNameWithText:self.currentArticle.publisherName];
        [articleDescriptionCell setArticleDescriptionWithText:self.currentArticle.aDescription];
        [articleDescriptionCell.articleTitleButton addTarget:self action:@selector(readPostTapped:) forControlEvents:UIControlEventTouchUpInside];
        [articleDescriptionCell.publisherButton addTarget:self action:@selector(publisherButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        articleDescriptionCell.isReadMoreTapped = self.isReadMoreTapped;
        [articleDescriptionCell.readMoreButton addTarget:self action:@selector(readMoreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [articleDescriptionCell.tagYourFriendsButton addTarget:self action:@selector(tagYourFriendsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        return articleDescriptionCell;
    }
    
    if(self.currentArticle.productList.count > 0) {
        
        NSInteger lastRowIndex = (self.currentArticle.productList.count * 2) + 2;
        
        if (lastRowIndex == (indexPath.row + 1)) {
            
            articleDetailFooterCell = [tableView dequeueReusableCellWithIdentifier:kCellArticleDetailsFooterCellIdentifier forIndexPath:indexPath];
            
            if (articleDetailFooterCell.delegate == nil) {
                articleDetailFooterCell.delegate = (id)self;
                articleDetailFooterCell.hashTagString =  self.currentArticle.hashTags;
                articleDetailFooterCell.hyperLinkArrayList = self.hashTagList;
                [articleDetailFooterCell createHyperLinkButtons:self.hashTagList];
            }
            
            [articleDetailFooterCell.shareThisArticleButton addTarget:self action:@selector(shareButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [articleDetailFooterCell.previousButton addTarget:self action:@selector(previousButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [articleDetailFooterCell.nextButton addTarget:self action:@selector(nextButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            
            if (self.dontShowPrevious_NextButtonAtFooter) {
                
                [articleDetailFooterCell.previousButton setHidden:YES];
                [articleDetailFooterCell.nextButton setHidden:YES];
                
            } else {
                
                // Disable the previous button when currentArticleIndex value is zero;
                if (self.currentArticleIndex == 0) {
                    [articleDetailFooterCell.previousButton setHidden:YES];
                    
                } else {
                    [articleDetailFooterCell.previousButton setHidden:NO];
                }
                
                // Disable the next button when currentArticleIndex value is equal to article List count;
                NSInteger articleListCount  = self.articleList.count == 0 ? 0 : self.articleList.count - 1;
                
                if (self.currentArticleIndex == articleListCount) {
                    [articleDetailFooterCell.nextButton setHidden:YES];
                } else {
                    
                    [articleDetailFooterCell.nextButton setHidden:NO];
                    
                }
            }
            
            articleDetailFooterCell.selectionStyle = UITableViewCellSelectionStyleNone;
            articleDetailFooterCell.contentView.backgroundColor = [UIColor clearColor];
            
            return articleDetailFooterCell;
        }
        
        NSInteger index = indexPath.row - 1;
        
        self.currentProduct = [self.currentArticle.productList objectAtIndex:index /2];
        
        if (index % 2 == 0) {         // Even number rows
            
            productImageViewCell = [tableView dequeueReusableCellWithIdentifier:cellProductImageCellIdentifier forIndexPath:indexPath];
            
            // Set product counts
            productImageViewCell.productNumberLabel.layer.cornerRadius = 16.0f;
            // Get the product number form indexpath.Calculation : (IndexPath.row/2) + 1  = ProductNumber
            productImageViewCell.productNumberLabel.text =[NSString stringWithFormat:@"%ld",(long)(index/2 + 1)];
            [productImageViewCell.productNumberLabel setFont:[MCFontManager GothamHTFBoldCondensedFontwithSize:25.0f]];
            
            
            // If it is loved product, loveImageView should change whenever tableView scroll happened.So checking if productId is already in the coreData make highLight YES for love image otherWise make it NO
            if([MCDataModelHandler favoriteProductsWithID:self.currentProduct.productId]) {
                [productImageViewCell.sfLoveButton setImage:[UIImage imageNamed:@"detailLoveHighlight.png"] forState:UIControlStateNormal];
            } else
                [productImageViewCell.sfLoveButton setImage:[UIImage imageNamed:@"detailLoveNormal.png"] forState:UIControlStateNormal];
            
            
            
            [productImageViewCell.sfLoveButton addTarget:self action:@selector(loveButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
            
            [productImageViewCell.productImageButton addTarget:self action:@selector(productClicked:event:) forControlEvents:UIControlEventTouchUpInside];
            
            productImageViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
            productImageViewCell.contentView.backgroundColor = [UIColor clearColor];
            
            return productImageViewCell;
            // Odd number rows
        } else if((index % 2) != 0) {
            
            productDetailsCell = [tableView dequeueReusableCellWithIdentifier:cellProductDetailsCellIdentifier];
            if (!productDetailsCell) {
                productDetailsCell = [[MCNewProductTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellProductDetailsCellIdentifier];
                
            }
            
            
            productDetailsCell.currentProduct = self.currentProduct;
            
            // excerptLabel Label.
            [productDetailsCell.excerptLabel setText:[NSString stringWithFormat:@"%@",self.currentProduct.excerpt] ];
            productDetailsCell.excerptMessage = (self.currentProduct.excerpt.length > 0) ? [NSString stringWithFormat:@"“%@”",self.currentProduct.excerpt] : nil;
            
            // Excerpt button event
            [productDetailsCell.excerptButton addTarget:self action:@selector(excerptButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
            [productDetailsCell.buyButton addTarget:self action:@selector(buyButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
            
            [productDetailsCell setBackgroundColor:[UIColor clearColor]];
            
            // Don't show the separator line for last row.
            if ((index/2) == self.currentArticle.productList.count - 1) {
                
                productDetailsCell.separatorLine.hidden = YES;
            } else {
                productDetailsCell.separatorLine.hidden = YES;
                
            }
            
            return productDetailsCell;
        }
    }
    
    UITableViewCell * defaultCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"defaultCell"];
    defaultCell.textLabel.font = [MCFontManager FrutigerRomanFontwithSize:16.0f];
    defaultCell.textLabel.text = NSLocalizedString(@"productDetail.NOProducts", @"");
    defaultCell.textLabel.textColor = [UIColor colorWithHexValue:@"#5A5A5A" alpha:1.0f];
    defaultCell.selectionStyle = UITableViewCellSelectionStyleNone;
    defaultCell.textLabel.numberOfLines = 0;
    defaultCell.textLabel.textAlignment = NSTextAlignmentCenter;
    return defaultCell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(self.currentArticle.productList == 0)
        return;
    
    NSInteger lastRowIndex = (self.currentArticle.productList.count * 2) + 2;
    
    if (indexPath.row == 0 || lastRowIndex == (indexPath.row + 1))
        return ;
    
    NSInteger index = indexPath.row - 1;
    if (index % 2 == 0) {
        
        MCProductItemDetailViewCell *productImageViewCell = (MCProductItemDetailViewCell *)cell;
        
        self.currentProduct = [self.currentArticle.productList objectAtIndex:index /2];
        
        if (!self.currentProduct.imageURL) {
            MCLog(@"ProductImage not available in Product Detail Page: %@ /n %@ /n %@",self.currentProduct.name,self.currentProduct.merchantname,self.currentProduct.productURL);
            
        }
        
        // Load the images
        [productImageViewCell.productImageView sd_setImageWithURL:[NSURL URLWithString:self.currentProduct.imageURL] placeholderImage:Nil options:SDWebImageProgressiveDownload];
        
    }
    
}

#pragma mark UIButton Events


- (void)nextButtonTapped:(UIButton *)sender {
    
    [self loadNextArticle:YES];
}


- (void)previousButtonTapped:(UIButton *)sender {
    
    [self loadNextArticle:NO];
    
}

- (IBAction)publisherButtonTapped:(id)sender {
    
    if(self.isPushedFromMagazineViewController) {
        [self .navigationController popViewControllerAnimated:YES];
        return;
    }
    
    MCMagazineViewController *magazineProfile = [MCMagazineViewController new];
    magazineProfile.publisherName = self.currentArticle.publisherName;
    magazineProfile.publisherGUID = self.currentArticle.publisherGUID;
    magazineProfile.pubCategory = self.currentArticle.category;
    magazineProfile.publisherURL = self.currentArticle.publisherURL;
    magazineProfile.publisherID = self.currentArticle.publisherID;
    [self logToMixPanel];
    [self.navigationController pushViewController:magazineProfile animated:YES];
    
}

- (IBAction)excerptButtonTapped:(UIButton*)button  event:(UIEvent*)event {
    
    NSIndexPath* indexPath = [_tableView indexPathForRowAtPoint:
                              [[[event touchesForView:button] anyObject]
                               locationInView:_tableView]];
    // Get the correct product details from currentArticle.productlist with help of indexPath.
    if(indexPath.row == 0)
        return;
    NSInteger index = indexPath.row - 1;
    
    self.currentProduct =  [self.currentArticle.productList objectAtIndex:index /2];
    
    MCWebViewController  *inAppBrowser  = [MCWebViewController new];
    PBSafariActivity *activity          = [[PBSafariActivity alloc] init];
    inAppBrowser.URL                    = [[MCWebAPIClient sharedClient]urlStringFromString:self.currentProduct.productURL];
    inAppBrowser.applicationActivities  = @[activity];
    inAppBrowser.excludedActivityTypes  = @[UIActivityTypeMail, UIActivityTypeMessage, UIActivityTypePostToWeibo];
    @try {
        [[Mixpanel sharedInstance]track:@"Article Title" properties:@{
                                                                      @"ProductTitle"    :   self.currentProduct.name,
                                                                      @"ProductURL"      :   self.currentProduct.productURL,
                                                                      @"ProductCategory" :   self.currentArticle.category,
                                                                      @"ArticleURL"      :   self.currentArticle.articleURL,
                                                                      @"Price"           :   self.currentProduct. price,
                                                                      @"RetailerName"    :   self.currentProduct.merchantname,
                                                                      @"Trending"        :   _trending
                                                                      }];
    }
    @catch (NSException *exception) {
        MCLog(@"Exception : %@",exception);
    }
    @finally {
        
    }
    
    // Viglink Monetization
    [[MCWebAPIClient sharedClient] viglinkMonetizationToLink:self.currentProduct.productURL];
    [self.navigationController pushViewController:inAppBrowser animated:YES];
}

- (IBAction)readPostTapped:(id)sender {
    
    MCWebViewController  *inAppBrowser      = [MCWebViewController new];
    PBSafariActivity *activity              = [[PBSafariActivity alloc] init];
    inAppBrowser.URL                        = [[MCWebAPIClient sharedClient]urlStringFromString:self.currentArticle.articleURL];
    inAppBrowser.applicationActivities      = @[activity];
    inAppBrowser.excludedActivityTypes      = @[UIActivityTypeMail, UIActivityTypeMessage, UIActivityTypePostToWeibo];
    [self.navigationController pushViewController:inAppBrowser animated:YES];
    
    // Viglink Monetization
    [[MCWebAPIClient sharedClient] viglinkMonetizationToLink:self.currentArticle.articleURL];
    
}

- (IBAction)buyButtonTapped:(UIButton*)button  event:(UIEvent*)event {
    
    [self productClicked:button event:event];
}




- (IBAction)productClicked:(UIButton *)button  event:(UIEvent *)event {
    
    NSIndexPath* indexPath = [_tableView indexPathForRowAtPoint:
                              [[[event touchesForView:button] anyObject]
                               locationInView:_tableView]];
    // Get the correct product details from currentArticle.productlist with help of indexPath.
    if(indexPath.row == 0)
        return;
    
    NSInteger index = indexPath.row - 1;
    self.currentProduct                 =  [self.currentArticle.productList objectAtIndex:index /2];
    
    MCWebViewController  *inAppBrowser  = [MCWebViewController new];
    PBSafariActivity *activity          = [[PBSafariActivity alloc] init];
    inAppBrowser.URL                    = [[MCWebAPIClient sharedClient] urlStringFromString:self.currentProduct.productURL];
    inAppBrowser.applicationActivities  = @[activity];
    inAppBrowser.excludedActivityTypes  = @[UIActivityTypeMail, UIActivityTypeMessage, UIActivityTypePostToWeibo];
    [self.navigationController pushViewController:inAppBrowser animated:YES];
    
    
    //MIXPANEL : CLICK TO RETAILER PRODUCT DETAILS
    @try {
        [[Mixpanel sharedInstance]track:@"Article Title" properties:@{
                                                                      @"ProductTitle"       :   self.currentProduct.name,
                                                                      @"ProductURL"         :   self.currentProduct.productURL,
                                                                      @"ProductCategory"    :   self.currentArticle.category,
                                                                      @"ArticleURL"         :   self.currentArticle.articleURL,
                                                                      @"Price"              :   self.currentProduct. price,
                                                                      @"RetailerName"       :   self.currentProduct.merchantname,
                                                                      @"Trending"           :   _trending
                                                                      }];
    }
    @catch (NSException *exception) {
        MCLog(@"Exception : %@",exception);
    }
    @finally {
        
    }
    // Viglink Monetization
    [[MCWebAPIClient sharedClient] viglinkMonetizationToLink:self.currentProduct.productURL];
}

- (IBAction)loveButtonTapped:(UIButton *)button  event:(UIEvent *)event{
    
    NSIndexPath* indexPath = [_tableView indexPathForRowAtPoint:
                              [[[event touchesForView:button] anyObject]
                               locationInView:_tableView]];
    
    // Touch event is taking the touch from bellow cell , so app is crashing .
    UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
    MCProductItemDetailViewCell* detailCell = nil;
    if([cell isKindOfClass:[MCProductItemDetailViewCell class]])
        detailCell = (MCProductItemDetailViewCell*)cell;
    else
        return;
    // Get the correct product details from currentArticle.productlist with help of indexPath.
    
    // return if indexpath.row == 0 , its article description cell
    if(indexPath.row == 0)
        return;
    
    NSInteger index = indexPath.row - 1;
    
    self.currentProduct =  [self.currentArticle.productList objectAtIndex:index /2];
    
    NSString *actionString  = @"";
    NSString *hudString     = @"";
    // check product is already added or not
    if([MCDataModelHandler favoriteProductsWithID:self.currentProduct.productId]) {
        actionString    = @"delete";
        hudString       = @"Removing Product...";
    } else {
        actionString    = @"add";
        hudString       = @"Adding Product...";
    }
    
    NSString * userGuid = [[NSUserDefaults standardUserDefaults]objectForKey:kUserGUIDKey];
    NSDictionary * product;
    @try {
        
        product = @{
                    @"action"   :   actionString,
                    @"userguid" :   userGuid,
                    @"pid"      :   self.currentProduct.pLoveId
                    };
    }
    @catch (NSException *exception) {
    }
    @finally {
        
    }
    
    
    MBProgressHUD *hud  = [MBProgressHUD showHUDAddedTo:[MCAppDelegate appDelegate].window animated:YES];
    hud.dimBackground   = YES;
    hud.labelText       = hudString;
    MKNetworkOperation * operation = [[MCWebAPIClient sharedClient] addRemoveProduct:product completeBlock:^(MKNetworkOperation* completeOperation,MCError *error)
                                      {
                                          [MBProgressHUD hideHUDForView:[MCAppDelegate appDelegate].window animated:YES];
                                          if(!error) {
                                              if([actionString isEqualToString:@"add"]) {
                                                  
                                                  [detailCell.sfLoveButton setImage:[UIImage imageNamed:@"detailLoveHighlight.png"] forState:UIControlStateNormal];
                                                  MCFavoriteProducts *product     = [MCDataModelHandler createFavoriteEntitiy];
                                                  NSString *productID             = self.currentProduct.productId;
                                                  product.productID               = productID;
                                                  product.productName             = self.currentProduct.name;
                                                  product.imageURl                = self.currentProduct.imageURL;
                                                  product.publisherURL            = self.currentArticle.publisherURL;
                                                  product.articleURL              = self.currentArticle.articleURL;
                                                  product.articleGUID             = self.currentArticle.articleGUID;
                                                  product.category                = self.currentArticle.category;
                                                  product.selectionDate           = [NSDate date];
                                                  NSError *error                  = nil;
                                                  
                                                  [[MCAppDelegate appDelegate].managedObjectContext save:&error];
                                                  if(!error)
                                                  {
                                                      MCLog(@"[%s]: saved profile info \n %@",__func__,product);
                                                  }
                                                  [self logLovedProductToMixpanel];
                                                  
                                              } else {
                                                  [detailCell.sfLoveButton setImage:[UIImage imageNamed:@"detailLoveNormal.png"] forState:UIControlStateNormal];
                                                  [MCDataModelHandler removeLoveItem:self.currentProduct.productId];
                                              }
                                              
                                          } else {
                                              
                                              if([[MCWebAPIClient sharedClient] isReachable])
                                                  [MCAlertView showAlertWithTitle:NSLocalizedString(@"Generic.UnknownTitle", @"") message:NSLocalizedString(@"config.Message", @"") cancelButtonTitle:@"OK" cancelBlock:^{} otherButtontitle:nil otherBlock:^{}];
                                              else
                                                  [MCAlertView showAlertWithTitle:NSLocalizedString(@"Reachability.UnreachableTitle", nil) message:NSLocalizedString(@"Reachability.UnreachableMessage",@"") cancelButtonTitle:NSLocalizedString(@"Alert.OK",@"") cancelBlock:^{} otherButtontitle:nil otherBlock:^{}];
                                          }
                                          
                                      }];
    [[MCWebAPIClient sharedClient]enqueueOperation:operation];
}

- (void) logLovedProductToMixpanel {
    //MIXPANEL : PRODUCT LOVED DETAILS
    @try
    {
        NSString *articleTitle = self.currentArticle.title;
        [[Mixpanel sharedInstance]track:@"product loved" properties:@{
                                                                      @"Product Title"  :   self.currentProduct.name,
                                                                      @"Article Title"  :   articleTitle,
                                                                      @"ProductURL"     :   self.currentProduct.productURL,
                                                                      @"Category"       :   self.currentArticle.category,
                                                                      @"ArticleURL"     :   self.currentArticle.articleURL,
                                                                      @"Price"          :   self.currentProduct. price,
                                                                      @"RetailerName"   :   self.currentProduct.merchantname,
                                                                      @"Trending"       :   _trending
                                                                      }];
    }
    @catch (NSException *exception) {
        MCLog(@"Exception : %@",exception);
    }
    @finally {
    }
}

// Tapping on share button in top grey bar.
- (IBAction)shareButtonTapped:(id)sender {
    
    
    NSString *loginID   = nil;
    NSString *APIKey    = nil;
    // First get the mobile web app article url if not exist then use article link.
    NSString * articleUrl = self.currentArticle.shareURL.length > 0 ? self.currentArticle.shareURL: self.currentArticle.articleURL;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.dimBackground = YES;
    hud.labelText = @"Loading...";
    
    __weak MCMagazineViewController *weakSelf = self;
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.bit.ly/v213/shorten?login=%@&apikey=%@&longUrl=%@&format=txt",loginID ,APIKey ,articleUrl]];
    NSURLRequest *request   = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:100];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         __strong MCMagazineViewController    *strongSelf = weakSelf;
         
         [MBProgressHUD hideHUDForView:strongSelf.navigationController.view animated:YES];
         
         NSString *articleShortLink = nil;
         if(!connectionError)
             articleShortLink = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
         
         // check if short url failed then pass actual url
         if(articleShortLink.length == 0)
             articleShortLink = articleUrl;
         
         NSString *title = [NSString stringWithFormat:@"Check this out: %@\n %@",strongSelf.currentArticle.title,articleUrl];
         NSString *link = [NSString stringWithFormat:@"\nDownload Shopfeed and find things you'll love.\n%@",ShortApplicationLink];
         NSString *contentSharingString =[NSString stringWithFormat:@"%@ \n %@", title,link];
         
         MCActivityProvider *ActivityProvider = [[MCActivityProvider alloc] init];
         ActivityProvider.getProductInfoString = contentSharingString;
         [MCMuluApiManager manager].SMSSharingText = contentSharingString;
         // check if short url failed then pass actual url
         NSURL *shareUrl = [NSURL URLWithString:strongSelf.currentArticle.imageURL];
         NSData* iData = [NSData dataWithContentsOfURL:shareUrl];
         NSArray *activityItems;
         if(iData)
             activityItems = @[ActivityProvider,[UIImage imageWithData:iData]];
         else
             activityItems = @[ActivityProvider];
         
         UIActivityViewController *ActivityView = nil;
         if (![FBDialogs canPresentOSIntegratedShareDialog]) { // No facebook account
             
             NSString *imagePath = @"";
             // A list of extensions to check against
             NSArray *imageExtensions = @[@"png", @"jpg", @"gif"]; //...
             
             // Iterate & match the URL objects from your checking results
             NSURL *url = [NSURL URLWithString:strongSelf.currentArticle.imageURL];
             NSString *extension = [url pathExtension];
             if ([imageExtensions containsObject:extension]) {
                 imagePath = strongSelf.currentArticle.imageURL;
             }
             
             NSDictionary *dictionary  = [NSDictionary dictionaryWithObjectsAndKeys:
                                          strongSelf.currentArticle.title,  @"name",
                                          imagePath,                        @"picture",
                                          articleUrl,                       @"link",
                                          strongSelf.currentArticle.aDescription, @"description",
                                          nil];
             
             if([UIDevice currentDevice].systemVersion.floatValue < 8.0) {
                 SFFacbookActivityIOS7 *facebookActivity7 = [[SFFacbookActivityIOS7 alloc] init];
                 facebookActivity7.shareDict = dictionary;
                 ActivityView = [[UIActivityViewController alloc]
                                 initWithActivityItems:activityItems
                                 applicationActivities:[NSArray arrayWithObject:facebookActivity7]];
                 
             } else {
                 SFFacbookActivityIOS8 *facebookActivity8 = [[SFFacbookActivityIOS8 alloc] init];
                 facebookActivity8.shareDict = dictionary;
                 ActivityView = [[UIActivityViewController alloc]
                                 initWithActivityItems:activityItems
                                 applicationActivities:[NSArray arrayWithObject:facebookActivity8]];
                 
             }
             
         } else {
             
             ActivityView = [[UIActivityViewController alloc]
                             initWithActivityItems:activityItems
                             applicationActivities:Nil];
         }
         
         
         [ActivityView setValue:@"This made me think of you" forKey:@"subject"];
         
         // to make hyperlink and image for app sharing Via Mails
         NSString* productStr = [NSString stringWithFormat:@"<html><body><p>Check this out: %@ <br><a href='%@'></a>%@</p>",strongSelf.currentArticle.title,articleUrl,articleUrl];
         NSMutableString *emailBody = [[NSMutableString alloc] initWithString:productStr];
         
         NSString * linkStr = [NSString stringWithFormat:@"<br/><br/><a href='%@'>Download Shopfeed and find things you'll love.</a>",ApplicationLink];
         
         [emailBody appendString:linkStr];
         UIImage *emailImage = [UIImage imageNamed:@"appStore.png"];
         NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(emailImage)];
         NSString *base64String = [imageData base64EncodedString];
         [emailBody appendString:[NSString stringWithFormat:@"<p><b><a href='%@'> <img src='data:image/png;base64,%@'></b></a></p>",ApplicationLink,base64String]];
         [emailBody appendString:@"</body></html>"];
         ActivityProvider.shareViaEmailInfoString  = emailBody ;
         //
         // to share content via twitter short message because of content character limit (160)
         NSString* twitterMessage = [NSString stringWithFormat:@"Check this out :\n%@\nDownload Shopfeed and find things you'll love.\n%@",articleShortLink,ShortApplicationLink];
         ActivityProvider.shareViaTwitterInfoString = twitterMessage;
         
         [ActivityView setExcludedActivityTypes:
          @[UIActivityTypeAssignToContact,
            UIActivityTypeCopyToPasteboard,
            UIActivityTypePrint,
            UIActivityTypeSaveToCameraRoll,
            UIActivityTypePostToWeibo]];
         [strongSelf presentViewController:ActivityView animated:YES completion:nil];
         [ActivityView setCompletionHandler:^(NSString *act, BOOL done)
          {
              NSString* shareSource = @"";
              if ( [act isEqualToString:UIActivityTypeMail] )           shareSource = @"Mail";
              if ( [act isEqualToString:UIActivityTypePostToTwitter] )  shareSource = @"Twitter";
              if ( [act isEqualToString:UIActivityTypePostToFacebook] ) shareSource = @"Facebook";
              if ( [act isEqualToString:UIActivityTypeMessage] )        shareSource = @"Message";
              if ( done ){
                  MCLog(@"successfully  %@",shareSource);
                  // TODO : COUNT HOW OFTEN SHARES ARE DONE AND ON WHICH PLATFORM - NOT IMPLEMENTED. ADDED CODE TO TRACK IMPRESSION AT MCACITIVITYPROVIDER
                  NSDictionary* parms ;
                  if(shareSource.length > 0)
                      parms =@{ shareSource: @"Shared Source",
                                @"Publisher"    :   strongSelf.currentArticle.publisherName,
                                @"URL"          :   strongSelf.currentArticle.articleURL,
                                @"Category"     :   strongSelf.currentArticle.category,
                                @"ArticleLink"  :   strongSelf.currentArticle.articleURL,
                                @"Trending"     :   _trending
                                };
                  else
                      parms = @{ @"Publisher"   :   strongSelf.currentArticle.publisherName,
                                 @"URL"         :   strongSelf.currentArticle.articleURL,
                                 @"Category"    :   strongSelf.currentArticle.category,
                                 @"ArticleLink" :   strongSelf.currentArticle.articleURL,
                                 @"Trending"    :   _trending
                                 };
                  @try {
                      [[Mixpanel sharedInstance]track:@"Article_detail page share" properties:parms];
                  }
                  @catch (NSException *exception) {
                      MCLog(@"Exception : %@",exception);
                  }
                  @finally {
                      
                  }
              }
          }];
     }];
}




#pragma mark MixPanel
-(void)logToMixPanel {
    
    @try {
        // send the detail of selected publisher
        NSDictionary *MixpanelParm =@{
                                      @"Publisher"      :   self.currentArticle.publisherName,
                                      @"Category"       :   self.currentArticle.category,
                                      @"Article URL"    :   self.currentArticle.articleURL,
                                      @"Article Title"  :   self.currentArticle.title,
                                      @"Trending":_trending
                                      };
        
        [[Mixpanel sharedInstance]track:@"clicks" properties:MixpanelParm];
        
    }
    @catch (NSException *exception) {
    }
    @finally {
    }
}

- (CGFloat)getArticleDiscriptionTextHeight:(NSString*)text
{
    NSAttributedString * attributeString = [[NSAttributedString alloc] initWithString:text];
    
    CGFloat finalHeight = 0.0f;
    CGFloat padding     = 10.0f;
    
    CGFloat textHeight  = [TTTAttributedLabel sizeThatFitsAttributedString:attributeString withConstraints:CGSizeMake(290, MAXFLOAT) limitedToNumberOfLines:0].height;
    textHeight = ceilf(textHeight) + padding;
    
    // Incase of @"" string its returing 10 height
    if(text.length == 0 || [text isEqualToString:@""])
        textHeight = 0.0f;
    
    if(textHeight >= kArticleDescriptionDefaultHeight && !self.isReadMoreTapped) {
        finalHeight = kArticleDescriptionDefaultHeight;
    } else {
        finalHeight = textHeight;
    }
    
    return finalHeight;
}

- (IBAction)readMoreButtonTapped:(UIButton*)sender {
    
    self.isReadMoreTapped = YES;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)tagYourFriendsButtonTapped:(UIButton*)sender {
    
    
    NSString *imagePath = @"";
    // A list of extensions to check against
    NSArray *imageExtensions = @[@"png", @"jpg", @"gif"]; //...
    
    // Iterate & match the URL objects from your checking results
    NSURL *url = [NSURL URLWithString:self.currentArticle.imageURL];
    NSString *extension = [url pathExtension];
    if ([imageExtensions containsObject:extension]) {
        imagePath = self.currentArticle.imageURL;
    }
    
    NSString * articleUrl = self.currentArticle.shareURL.length > 0 ? self.currentArticle.shareURL: self.currentArticle.articleURL;
    
    FBLinkShareParams *params = [[FBLinkShareParams alloc] init];
    params.link         = [NSURL URLWithString:articleUrl];
    params.name         = self.currentArticle.title;
    params.caption      = @"";
    params.picture      = [NSURL URLWithString:imagePath];
    params.linkDescription = self.currentArticle.aDescription;
    
    if ([FBDialogs canPresentShareDialogWithParams:params]) {
        [FBDialogs presentShareDialogWithLink:params.link
                                         name:params.name
                                      caption:params.caption
                                  description:params.linkDescription
                                      picture:params.picture
                                  clientState:nil
                                      handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                          if(error) {
                                          } else {
                                              NSLog(@"result %@", results);
                                          }
                                      }];
    } else {
        
        NSDictionary *dictionary  = [NSDictionary dictionaryWithObjectsAndKeys:
                                     imagePath,                         @"picture",
                                     articleUrl,                        @"link",
                                     self.currentArticle.title,         @"name",
                                     self.currentArticle.aDescription,  @"description",
                                     nil];
        
        
        [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                               parameters:dictionary
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                      if (error) {
                                                      } else {
                                                          if (result == FBWebDialogResultDialogNotCompleted) {
                                                              // User cancelled.
                                                          } else {
                                                              NSDictionary *urlParams = [MCMagazineViewController parseURLParams:[resultURL query]];
                                                              
                                                              if (![urlParams valueForKey:@"post_id"]) {
                                                                  // User cancelled.
                                                              } else {
                                                                  // User clicked the Share button
                                                                  NSString *result = [NSString stringWithFormat: @"Posted story, id: %@", [urlParams valueForKey:@"post_id"]];
                                                                  NSLog(@"result %@", result);
                                                                  
                                                              }
                                                          }
                                                      }
                                                  }];
    }
    
    
    
}

#pragma mark  Cell Height

- (float)heightForArticleTopicTagForDescripitionCell {
    
    float totalWidth = 0; // If total width cross more than the view width, display the hashTag in next line
    float viewWidth  = self.view.bounds.size.width - 30;
    float height = 0.0f;
    
    for (NSString *indexValue in self.hashTagList) {
        
        float topicWidth = [MCArticleDescriptionCell getWidthFromText:indexValue];
        totalWidth += topicWidth + 5;
        if (totalWidth > viewWidth ) {
            height =  37.0f;
        } else
            height = 16.0f;
    }
    
    return height;
    
}

- (float)heightForArticleTopicTagForFooterCell {
    
    float totalWidth = 27;
    float viewWidth  = self.view.bounds.size.width - 20;
    float height = 0.0f;
    
    for (NSString *indexValue in self.hashTagList) {
        
        float topicWidth = [SFArticleDetailFooterTableViewCell getWidthFromTopicTag:indexValue];
        
        totalWidth += topicWidth + 5;
        if (totalWidth > viewWidth ) {
            height =  37.0f;
        } else
            height = 16.0f;
        
    }
    
    return height;
    
}

#pragma mark Class Method

+ (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}


@end
