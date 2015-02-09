//
//  MCMagazineViewController.h
//  Monocept
//
//  Created by Jayaganesh G. on 2/9/15.
//  Copyright (c) 2015 Monocept. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCArticleDescriptionCell.h"

typedef  enum {
    MCProductDetailsImageCell = 0,
    MCProductItemDetailsCell
} MCProductDetailsCellType;

@interface MCMagazineViewController : MCBaseViewController < MCArticleDescriptionCellDelegate >

@property (weak, nonatomic) IBOutlet UITableView    *tableView;
@property (weak, nonatomic) IBOutlet UIImageView    *footerBackgroundImage;
@property (weak, nonatomic) IBOutlet UILabel     *photoCreditLabel;

@property (strong,  nonatomic) NSIndexPath      *scrollIndexPath;
@property (nonatomic) BOOL      isPushedFromMagazineViewController;
@property (nonatomic) BOOL      isPushedFromSearchViewController;
@property (nonatomic) BOOL      dontShowPrevious_NextButtonAtFooter;

@property (strong, nonatomic) MCProduct *currentProduct;
@property (strong, nonatomic) MCArticle *currentArticle;
@property (strong, nonatomic) NSArray   *articleList;

@property NSInteger currentArticleIndex;

@end
