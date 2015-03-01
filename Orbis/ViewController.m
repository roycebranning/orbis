//
//  ViewController.m
//  Orbis
//
//  Created by Michael Krumdick on 2/27/15.
//  Copyright (c) 2015 ND Fresh Team. All rights reserved.
//

#import "ViewController.h"
#import "WhirlyGlobeComponent.h"
#import "SVModalWebViewController.h"


@interface ViewController () <UITableViewDelegate>

- (void) addCountries;
- (void) addAnnotation:(NSString *)title withSubtitle:(NSString *)subtitle at: (MaplyCoordinate)coord;

@end

@implementation ViewController
{
    MaplyBaseViewController *theViewC;
    WhirlyGlobeViewController *globeViewC;
    MaplyViewController *mapViewC;
    NSDictionary *vectorDict;
}

// Set this to false for a map
const bool DoGlobe = true;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (DoGlobe)
    {
        globeViewC = [[WhirlyGlobeViewController alloc] init];
        theViewC = globeViewC;
    } else {
        mapViewC = [[MaplyViewController alloc] init];
        theViewC = mapViewC;
    }
    // If you're doing a globe
    if (globeViewC != nil)
        globeViewC.delegate = self;
    
    // If you're doing a map
    if (mapViewC != nil)
        mapViewC.delegate = self;
    
    // Create an empty globe or map and add it to the view
    [self.view addSubview:theViewC.view];
    theViewC.view.frame = self.view.bounds;
    [self addChildViewController:theViewC];
    
    // we want a black background for a globe, a white background for a map.
    theViewC.clearColor = (globeViewC != nil) ? [UIColor blackColor] : [UIColor whiteColor];
    
    // and thirty fps if we can get it ­ change this to 3 if you find your app is struggling
    theViewC.frameInterval = 2;
    
    // add the capability to use the local tiles or remote tiles
    bool useLocalTiles = false;
    
    // we'll need this layer in a second
    MaplyQuadImageTilesLayer *layer;
    
    if (useLocalTiles)
    {
        MaplyMBTileSource *tileSource =
        [[MaplyMBTileSource alloc] initWithMBTiles:@"geography­-class_medres"];
        layer = [[MaplyQuadImageTilesLayer alloc]
                 initWithCoordSystem:tileSource.coordSys tileSource:tileSource];
    } else {
        // Because this is a remote tile set, we'll want a cache directory
        NSString *baseCacheDir =
        [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)
         objectAtIndex:0];
        NSString *aerialTilesCacheDir = [NSString stringWithFormat:@"%@/osmtiles/",
                                         baseCacheDir];
        int maxZoom = 18;
        
        // MapQuest Open Aerial Tiles, Courtesy Of Mapquest
        // Portions Courtesy NASA/JPL­Caltech and U.S. Depart. of Agriculture, Farm Service Agency
        MaplyRemoteTileSource *tileSource =
        [[MaplyRemoteTileSource alloc]
         initWithBaseURL:@"http://otile1.mqcdn.com/tiles/1.0.0/sat/"
         ext:@"png" minZoom:0 maxZoom:maxZoom];
        tileSource.cacheDir = aerialTilesCacheDir;
        layer = [[MaplyQuadImageTilesLayer alloc]
                 initWithCoordSystem:tileSource.coordSys tileSource:tileSource];
    }
    layer.handleEdges = (globeViewC != nil);
    layer.coverPoles = (globeViewC != nil);
    layer.requireElev = false;
    layer.waitLoad = false;
    layer.drawPriority = 0;
    layer.singleLevelLoading = false;
    [theViewC addLayer:layer];
    
    // start up over San Francisco
    if (globeViewC != nil)
    {
        globeViewC.height = 1.1;
        [globeViewC animateToPosition:MaplyCoordinateMakeWithDegrees(-90.1978,38.6272)
                                 time:1.0];
    } else {
        mapViewC.height = 1.0;
        [mapViewC animateToPosition:MaplyCoordinateMakeWithDegrees(-122.4192,37.7793)
                               time:1.0];
    }
    
    // set the vector characteristics to be pretty and selectable
    vectorDict = @{
                   kMaplyColor: [UIColor whiteColor],
                   kMaplySelectable: @(true),
                   kMaplyVecWidth: @(4.0)};
    
    // add the countries
    [self addCountries];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addCountries
{
    // handle this in another thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),
                   ^{
                       NSArray *allOutlines = [[NSBundle mainBundle] pathsForResourcesOfType:@"geojson" inDirectory:nil];
                       
                       for (NSString *outlineFile in allOutlines)
                       {
                           NSData *jsonData = [NSData dataWithContentsOfFile:outlineFile];
                           if (jsonData)
                           {
                               MaplyVectorObject *wgVecObj = [MaplyVectorObject VectorObjectFromGeoJSON:jsonData];
                               
                               // the admin tag from the country outline geojson has the country name ­ save
                               NSString *vecName = [[wgVecObj attributes] objectForKey:@"ADMIN"];
                               wgVecObj.userObject = vecName;
                               
                               // add the outline to our view
                               [theViewC addVectors:[NSArray arrayWithObject:wgVecObj] desc:vectorDict];
                               // If you ever intend to remove these, keep track of the MaplyComponentObjects above.
                           }
                       }
                   });
}

- (void)addAnnotation:(NSString *)title withSubtitle:(NSString *)subtitle at:(MaplyCoordinate)coord
{
    [theViewC clearAnnotations];
    
    MaplyAnnotation *annotation = [[MaplyAnnotation alloc] init];
    annotation.title = title;
    annotation.subTitle = subtitle;
    [theViewC addAnnotation:annotation forPoint:coord offset:CGPointZero];
}

// Unified method to handle the selection
- (void) handleSelection:(MaplyBaseViewController *)viewC
                selected:(NSObject *)selectedObj
{
    
    // NSString *subtitle = [NSString stringWithFormat: @"%@",webViewController.url];
    
    // ensure it's a MaplyVectorObject. It should be one of our outlines.
    if ([selectedObj isKindOfClass:[MaplyVectorObject class]])
    {
        MaplyVectorObject *theVector = (MaplyVectorObject *)selectedObj;
        MaplyCoordinate location;
        
        if ([theVector centroid:&location])
        {
            NSString *country = (NSString *)theVector.userObject;
            [self addAnnotation:country withSubtitle:@"Tap Country Again to View News" at:location];
            if ([country isEqualToString:self.lastSelect]){
                NSString *baseURL = @"http://gravity.answers.com/endpoint/searches/news?key=ab45bcbb7d58ce62eb0e9084ae78ba9ace55a9e9&limit=12&q=";
                NSArray *array = [country componentsSeparatedByString:@" "];
                NSString *skimArray = [[NSString alloc]init];
                for (id part in array){
                    if (![part isEqualToString:@"of"] && ![part isEqualToString:@"the"] && ![part isEqualToString:@"South"] &&![part isEqualToString:@"North"] && ![part isEqualToString:@"New"]){
                    skimArray = [skimArray stringByAppendingString:@"%20"];
                    skimArray = [skimArray stringByAppendingString:part];
                    }
                }
                NSString *safeString = [[NSString alloc] initWithFormat:@"%@", skimArray];
                NSString *newURL = [baseURL stringByAppendingString:safeString];
                NSLog(@"%@", newURL);
                NSData *allNewsInfo = [[NSData alloc] initWithContentsOfURL:
                                       [NSURL URLWithString:newURL]];
                NSError *error;
                NSMutableDictionary *allNews = [NSJSONSerialization
                                                JSONObjectWithData:allNewsInfo
                                                options:NSJSONReadingMutableContainers
                                                error:&error];
                
                if(([allNews[@"total_count"] integerValue]) == 0){
                    [self addAnnotation:country withSubtitle:@"No News Available" at:location];
                }else{
                    if(error)
                    {
                        NSLog(@"%@", [error localizedDescription]);
                    }
                    
                    else{
                        NSDictionary* anArticle;
                        self.listOfArticles = [[NSMutableArray alloc] init];
                        for(int i = 0; i < ((NSArray *)allNews[@"result"]).count; i++){
                            
                            anArticle = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [[[allNews objectForKey:@"result"] objectAtIndex:i] objectForKey:@"title"], @"title",
                                         [[[allNews objectForKey:@"result"] objectAtIndex:i] objectForKey:@"canonical_url"], @"link",
                                         nil];
                            BOOL doAdd = false;
                            NSArray *countryCompare= [[NSArray alloc]init];
                            countryCompare = [[[[allNews objectForKey:@"result"] objectAtIndex:i] objectForKey:@"title"] componentsSeparatedByString:@" "];
                            for (id word in countryCompare){
                                if ([array containsObject:word]){
                                    doAdd = true;
                                }
                            }
                            if(doAdd){
                                [self.listOfArticles addObject: anArticle];
                            }
                        }
                    }
                _articleView    =   [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
                _articleView.dataSource      =   self;
                _articleView.delegate        =   self;
                    if ([self.listOfArticles count] > 0) {
                        [self.view addSubview:_articleView];
                    }else{
                        [self addAnnotation:country withSubtitle:@"No News Available" at:location];
                    }
                
                }
            }
            self.lastSelect = (NSString *)theVector.userObject;
        }
    }
}

// This is the version for a globe
- (void) globeViewController:(WhirlyGlobeViewController *)viewC
                   didSelect:(NSObject *)selectedObj
{
    [self handleSelection:viewC selected:selectedObj];
}

// This is the version for a map
- (void) maplyViewController:(MaplyViewController *)viewC
                   didSelect:(NSObject *)selectedObj
{
    [self handleSelection:viewC selected:selectedObj];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"%@", indexPath);
    NSString* articleURL = self.listOfArticles[indexPath.row][@"link"];
    SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:articleURL];
    [self presentViewController:webViewController animated:YES completion:NULL];
    [_articleView removeFromSuperview];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.listOfArticles count];
}

- (UITableViewCell *)tableView:(UITableView *)tmpTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier         =   @"MainCell";
    UITableViewCell *cell               =   [tmpTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (nil == cell) {
        cell    =   [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [[self.listOfArticles objectAtIndex:indexPath.row]objectForKey:@"title"];
    return cell;
}
@end

