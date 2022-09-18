#import <substrate.h>
#import <objc/runtime.h>


static dispatch_source_t _timer;
static UILabel *fpsLabel;

double FPSPerSecond = 0;

static void startRefreshTimer(){
	_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), (1.0/5.0) * NSEC_PER_SEC, 0);

    dispatch_source_set_event_handler(_timer, ^{
    	[fpsLabel setText:[NSString stringWithFormat:@"%.1lf",FPSPerSecond]];

    	NSLog(@"%.1lf",FPSPerSecond);

    });
    dispatch_resume(_timer); 
}

#pragma mark ui
#define kFPSLabelWidth 50
#define kFPSLabelHeight 20
%group ui
%hook UIWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fpsLabel= [[UILabel alloc] initWithFrame:CGRectMake(285, 25, kFPSLabelWidth, kFPSLabelHeight)];
        fpsLabel.font=[UIFont fontWithName:@"Helvetica-Bold" size:16];
        fpsLabel.textAlignment=NSTextAlignmentRight;
        fpsLabel.userInteractionEnabled=NO;

        UIColor *color = [UIColor colorWithRed: 0.99 green: 0.80 blue: 0.00 alpha: 1.00];
		[fpsLabel setTextColor:color];

        [self addSubview:fpsLabel];
        startRefreshTimer();
    });
	return %orig;
}
%end
%end


void frameTick(){
	static double FPS_temp = 0;
	static double starttick = 0;
	static double endtick = 0;
	static double deltatick = 0;
	static double frameend = 0;
	static double framedelta = 0;
	static double frameavg = 0;
	
	if (starttick == 0) starttick = CACurrentMediaTime()*1000.0;
	endtick = CACurrentMediaTime()*1000.0;
	framedelta = endtick - frameend;
	frameavg = ((9*frameavg) + framedelta) / 10;
    FPSPerSecond = 1000.0f / (double)frameavg;
	frameend = endtick;
	
	FPS_temp++;
	deltatick = endtick - starttick;
	if (deltatick >= 1000.0f) {
		starttick = CACurrentMediaTime()*1000.0;
		FPSPerSecond = FPS_temp - 1;
		FPS_temp = 0;
	}
	
	return;
}


#pragma mark gl
%group gl
%hook EAGLContext 
- (BOOL)presentRenderbuffer:(NSUInteger)target{
	BOOL ret=%orig;
	frameTick();
	return ret;
}
%end
%end

#pragma mark metal
%group metal
%hook CAMetalDrawable
- (void)present{
	%orig;
	frameTick();
}
- (void)presentAfterMinimumDuration:(CFTimeInterval)duration{
	%orig;
	frameTick();
}
- (void)presentAtTime:(CFTimeInterval)presentationTime{
	%orig;
	frameTick();
}
%end
%end


%ctor{
	NSLog(@"ctor: FPSIndicator");

	%init(ui);
	%init(gl);
	%init(metal);
}
