//
//  MPMillennialAdapter.m
//  MoPub
//
//  Created by Andrew He on 5/1/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import "MPMillennialAdapter.h"
#import "CJSONDeserializer.h"
#import "MPAdView.h"
#import "MPLogging.h"

#define MM_SIZE_320x53	CGSizeMake(320, 53)
#define MM_SIZE_300x250 CGSizeMake(300, 250)

@interface MPMillennialAdapter ()
@property (nonatomic, retain) MMAdView *mmAdView;
@property (nonatomic, assign) CGSize mmAdSize;
@property (nonatomic, assign) MMAdType mmAdType;
@property (nonatomic, copy) NSString * mmAdApid;
- (void)setAdPropertiesFromNativeParams:(NSDictionary *)params;
- (void)tearDownExistingAdView;
@end


@implementation MPMillennialAdapter
@synthesize mmAdView = _mmAdView;
@synthesize mmAdSize = _mmAdSize;
@synthesize mmAdType = _mmAdType;
@synthesize mmAdApid = _mmAdApid;

- (void)dealloc
{
	[self tearDownExistingAdView];
	[super dealloc];
}

- (void)getAdWithParams:(NSDictionary *)params
{
	NSData *hdrData = [(NSString *)[params objectForKey:@"X-Nativeparams"] 
					   dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *hdrParams = [[CJSONDeserializer deserializer] deserializeAsDictionary:hdrData
																				  error:NULL];
	[self setAdPropertiesFromNativeParams:hdrParams];
	[self tearDownExistingAdView];
	
	self.mmAdView = [MMAdView adWithFrame:(CGRect){{0.0, 0.0}, self.mmAdSize} 
									 type:self.mmAdType
									 apid:self.mmAdApid
								 delegate:self
								   loadAd:NO
							   startTimer:NO];
	[self.mmAdView refreshAd];
}

- (void)setAdPropertiesFromNativeParams:(NSDictionary *)params
{
	CGFloat width = [(NSString *)[params objectForKey:@"adWidth"] floatValue];
	CGFloat height = [(NSString *)[params objectForKey:@"adHeight"] floatValue];
	if (width == 300.0 && height == 250.0)
	{
		self.mmAdSize = MM_SIZE_300x250;
		self.mmAdType = MMBannerAdRectangle;
	}
	else
	{
		self.mmAdSize = MM_SIZE_320x53;
		self.mmAdType = MMBannerAdTop;
	}
	
	self.mmAdApid = [params objectForKey:@"adUnitID"];
}

/* 
 * Safely tears down and releases this adapter's MMAdView, if it exists.
 * Per: http://wiki.millennialmedia.com/index.php/Apple_SDK#adWithFrame
 */
- (void)tearDownExistingAdView
{
	self.mmAdView.refreshTimerEnabled = NO;
	self.mmAdView.delegate = nil;
	self.mmAdView = nil;
}

#pragma mark -
#pragma mark MMAdViewDelegate

- (NSDictionary *)requestData 
{
	return [NSDictionary dictionaryWithObjectsAndKeys:@"mopubsdk", @"vendor", nil];
}

- (void)adRequestSucceeded:(MMAdView *)adView
{
	[self.adView setAdContentView:adView];
	[self.adView adapterDidFinishLoadingAd:self shouldTrackImpression:YES];
}

- (void)adRequestFailed:(MMAdView *)adView
{
	[self.adView adapter:self didFailToLoadAdWithError:nil];
}

- (void)adWasTapped:(MMAdView *)adView
{
	[self.adView userActionWillBeginForAdapter:self];
}

- (void)applicationWillTerminateFromAd
{
	[self.adView userWillLeaveApplicationFromAdapter:self];
}

- (void)adModalWasDismissed
{
	[self.adView userActionDidEndForAdapter:self];
}

@end
