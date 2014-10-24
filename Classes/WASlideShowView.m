#import "WASlideShowView.h"
#import "UIColor+WAAdditions.h"
#import "UIView+WAModuleView.h"
#import "WAModuleViewController.h"
#import "WAUtilities.h"
#import "WAOperationsManager.h"

#import "NSString+WAURLString.h"
#import "NSBundle+WAAdditions.h"

//  Copyright 2011 WidgetAvenue - Librelio. All rights reserved.


@implementation WASlideShowView
{
    NSArray *images;
}

@synthesize scrollView,view1,view2,transition,timerCount,timer,repeat,currentViewController,resizeMode,scrollDirection;



- (NSString *) urlString
{
    return urlString;
}

- (void) setUrlString: (NSString *) theString
{
    if (urlString){
		//Do nothing
		
		
	}
	else {
		//Do once only
		urlString = [[NSString alloc]initWithString: theString];
        //Stop the queue in order to avoid memory issues
        [[[WAOperationsManager sharedManager] defaultQueue]setSuspended:YES];
        
        self.backgroundColor = [UIColor blackColor];//This is the default
        NSString *bgColorString = [urlString valueOfParameterInUrlStringforKey:@"wabgcolor"];
		if (bgColorString) self.backgroundColor = [UIColor colorFromString:bgColorString];
        
		// Create view1 and add it to the view .
		view1 = [[UIImageView alloc] init];
		view1.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        
		view1.autoresizingMask = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin);
		[self addSubview:view1];
		view1.contentMode = UIViewContentModeScaleToFill;
		view1.backgroundColor = [UIColor clearColor];
        
		// Create scrollview and add it to the view .
		scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
		scrollView.autoresizingMask  = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin);
		[self addSubview:scrollView];
		scrollView.bounces = YES;
		scrollView.pagingEnabled = YES;
		scrollView.delegate = self;
		scrollView.userInteractionEnabled = YES;
		scrollView.backgroundColor = [UIColor clearColor];

        

        NSString * transitionString = [urlString valueOfParameterInUrlStringforKey:@"watransition"];
        if ([transitionString isEqualToString:@"none"]) transition = SlideShowTransitionNone;
        else if ([transitionString isEqualToString:@"dissolve"]) transition = SlideShowTransitionDissolve;
        else transition = SlideShowTransitionMoveIn;
        
        
        //Populate the array of image paths
        NSArray * urlStringsArray = [WAUtilities arrayOfImageUrlStringsForUrlString:urlString];
        NSMutableArray *tempArray= [NSMutableArray array];
        for (NSString * tempUrlString in urlStringsArray){
            NSString * tempPath = [[NSBundle mainBundle] pathOfFileWithUrl:tempUrlString];
            if (tempPath) [tempArray addObject:tempPath];
        }
        imagePathArray = [[NSArray alloc]initWithArray:tempArray];
        int count = (int)[imagePathArray count];
        
        NSMutableArray *m_images = [[NSMutableArray alloc] init];
        for(NSString *path in imagePathArray)
            [m_images addObject:[UIImage imageWithContentsOfFile:path]];
        images = [NSArray arrayWithArray:m_images];
        [m_images release];
        
        
        // find expected scroll direction
        scrollDirection = [self findExpectedScrollDirection];
        
        switch (transition) {
            case SlideShowTransitionMoveIn: {
                //In this case, we put all images inside the scrollview
                [self insertTransitionMoveInImages];
                break;
                
            }
            default:{
                view1.image = [images objectAtIndex:count-1];
                
                view1.frame = [WAUtilities frameForSize:view1.image.size withScreenSize:self.frame.size resizeMode:resizeMode];
                
                scrollView.contentSize = CGSizeMake(2000000.0, self.frame.size.height);//Infinite size!
                scrollView.pagingEnabled = NO;
                scrollView.showsHorizontalScrollIndicator = NO;
                
                [scrollView setContentOffset:CGPointMake(1000000, 0)];
                break;
                
                
                
            }
                
                
                
        }
         //set automatic timer.Value is given by the wadelay arg
        
        CGFloat timeInterval = [[urlString valueOfParameterInUrlStringforKey:@"wadelay"]floatValue];
        if (timeInterval) {
            repeat = [[urlString valueOfParameterInUrlStringforKey:@"warepeat"]intValue];//the number of times the slideshow should repeat; default is infinite
            timerCount = 0;
            timer = [[NSTimer scheduledTimerWithTimeInterval: timeInterval/1000 target:self selector:@selector(onTimer) userInfo:nil repeats:YES]retain];
        }
        
        //Gesture recognizers
		UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
		singleTapGestureRecognizer.numberOfTapsRequired = 1;
		singleTapGestureRecognizer.delegate = self;
		[self addGestureRecognizer:singleTapGestureRecognizer];
		[singleTapGestureRecognizer release];


    }
}

- (SlideShowScrollDirection)findExpectedScrollDirection
{
    NSInteger bal = 0;
    for(UIImage *image in images)
    {
        NSInteger ratio = image.size.width / image.size.height;
        if(resizeMode == ModuleResizeModeFit)
        {
            if(ratio > 1.0)
                bal += 1; // fits in width
            else
                bal -= 1; // fits in height
        }
        else
        {
            if(ratio > 1.0)
                bal -= 1; // fits in height
            else
                bal += 1; // fits in width
        }
    }
    return bal < 0 ? SlideShowScrollHorizontally : SlideShowScrollVertically;
}

- (void)insertTransitionMoveInImages
{
    int count = (int)[images count];
    for (int i = 0;i<count;i++) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[images objectAtIndex:count-(i+1)]];//Start with the last image
        
        CGRect rect = [WAUtilities frameForSize:imageView.image.size withScreenSize:self.frame.size resizeMode:resizeMode];
        imageView.frame = CGRectMake(rect.origin.x +
                                     (scrollDirection == SlideShowScrollHorizontally ? i : 0) * self.frame.size.width,
                                     rect.origin.y +
                                     (scrollDirection == SlideShowScrollVertically ? i : 0) * self.frame.size.height,
                                     rect.size.width, rect.size.height);
        imageView.contentMode = UIViewContentModeScaleToFill;
        [scrollView addSubview:imageView];
        imageView.autoresizingMask  = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin);
        [imageView release];
    }
    scrollView.contentSize = [self contentSizeForTransitionMoveInMode];

}

- (CGSize)contentSizeForTransitionMoveInMode
{
    return CGSizeMake((scrollDirection == SlideShowScrollHorizontally ? [images count] : 1) * self.frame.size.width,
                      (scrollDirection == SlideShowScrollVertically ? [images count] : 1) * self.frame.size.height);
}

#pragma mark end scrollDelegateFunction
- (void)scrollViewDidScroll:(UIScrollView *)sender {
	
	if (transition ==SlideShowTransitionNone){
		//In this case, the scrollview is transparent, the real images are behind.
		CGFloat offset = scrollView.contentOffset.x;
		int count = (int)[imagePathArray count];
		int tempInt = floor((1000000-offset)*2/count);
		int imageNumber = (tempInt-1) %count;
		if (imageNumber<0) imageNumber +=count;
		view1.image = [UIImage imageWithContentsOfFile:[imagePathArray objectAtIndex:imageNumber]];
	}
	
	
	

}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
	[timer invalidate];//Does not work, for some reason
	
}

- (void) onTimer {
	timerCount = timerCount +1;
	int count = (int)[imagePathArray count];
	if (repeat &&(timerCount>=count*repeat)){
		[timer invalidate];
	}
	else{
		int nOffset = timerCount%count;
		switch (transition) {
			case SlideShowTransitionMoveIn: {
				CGFloat offset = scrollView.frame.size.width*nOffset;
				[scrollView setContentOffset:CGPointMake(offset, 0) animated:YES];
				//[[self.superview viewWithTag:99] setText:[NSString stringWithFormat:@"%f",scrollView.contentOffset.x]];
				break;
				
			}
			default:{
				view1.image = [UIImage imageWithContentsOfFile:[imagePathArray objectAtIndex:nOffset]];
				break;
				
				
				
			}
				
				
				
		}
		
		
	}
	
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    if ([self isRootModule]){
        [[self firstAvailableUIViewController]  dismissModalViewControllerAnimated:YES];
    }
    else{
       	WAModuleViewController * moduleViewController = [[WAModuleViewController alloc]init];
        moduleViewController.moduleUrlString= urlString;
        moduleViewController.initialViewController= (WAModuleViewController *)[self firstAvailableUIViewController];
        moduleViewController.containingView= self.superview;
        moduleViewController.containingRect= CGRectZero;//This forces full screen
        [moduleViewController pushViewControllerIfNeededAndLoadModuleView];
        [moduleViewController release];
 
        
    }
	
}


- (void) resetSlideShow{
		[scrollView setContentOffset:CGPointMake(0, 0)];
		int count = (int)[imagePathArray count];
		scrollView.contentSize = CGSizeMake(self.frame.size.width * count, self.frame.size.height);
}

- (void)willMoveToSuperview:(UIView *)newSuperview{
	if (!newSuperview){//In this case, the view is being removed from superview
		[timer invalidate];//This is important to avoid memory leaks
	}

}


- (void)dealloc {

	[timer release];
	[imagePathArray release];
	[urlString release];
	[scrollView release];
	[view1 release];
	[view2 release];
    [super dealloc];
}

#pragma mark -
#pragma mark ModuleView protocol

- (void)moduleViewWillAppear:(BOOL)animated{
	
	
}
- (void) moduleViewDidAppear{
}


- (void) moduleViewWillDisappear:(BOOL)animated{
}



- (void) moduleWillRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
}
- (void) moduleWillAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [self resetSlideShow];

	
}

- (void) jumpToRow:(int)row{
    
}

@end
