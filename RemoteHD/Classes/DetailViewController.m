//
//  DetailViewController.m
//  RemoteHD
//
//  Created by Fabrice Dewasmes on 19/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DetailViewController.h"
#import "SessionManager.h"
#import "DAAPResponseadbs.h"
#import "DAAPResponsemlit.h"
#import "DAAPResponsemlog.h"
#import "DAAPResponseabro.h"
#import "DAAPResponseavdb.h"
#import "DAAPResponsemlcl.h"
#import "AlbumsOfArtistController.h"

@implementation DetailViewController

@synthesize results;
@synthesize indexList;
@synthesize delegate;
@synthesize currentTrack;
@synthesize currentAlbum;
@synthesize currentArtist;
@synthesize artistDatasource;


#pragma mark -
#pragma mark Initialization

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
    }
    return self;
}
*/


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = NO;
	
	results = [[NSMutableArray alloc] init];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusUp:) name:@"statusUpdate" object:nil];
}

- (void) viewWillAppear:(BOOL)animated{
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.indexList count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	//NSString *letter = [arrayOfCharacters objectAtIndex:section];
	//return [[indexedResults objectForKey:letter] count];
	long res = [[(DAAPResponsemlit *)[self.indexList objectAtIndex:section] mshn] longValue];
	
	return res;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	NSMutableArray *chars = [[[NSMutableArray alloc] init] autorelease];
	for (DAAPResponsemlit *mlit in self.indexList) {
		[chars addObject:[mlit mshc]];
	}
	//return arrayOfCharacters;
	return chars;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
	/*NSInteger count = 0;
	for(NSString *character in arrayOfCharacters)
	{
		if([character isEqualToString:title])
			return count;
		count ++;
	}
	return 0;// in case of some eror donot crash d application*/
	NSInteger count = 0;
	for(DAAPResponsemlit *mlit in self.indexList)
	{
		if([mlit.mshc isEqualToString:title])
			return count;
		count ++;
	}
	return 0;
	
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	/*if([arrayOfCharacters count]==0)
		return @"";
	return [arrayOfCharacters objectAtIndex:section];*/
	return [(DAAPResponsemlit *)[self.indexList objectAtIndex:section] mshc];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"TrackCell";
    
	TrackCustomCellClass *cell = (TrackCustomCellClass *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		cell = [[[NSBundle mainBundle] loadNibNamed: @"TrackCustomCell" owner: self options: nil] objectAtIndex: 0];
    }
    
	long offset = [[(DAAPResponsemlit *)[self.indexList objectAtIndex:indexPath.section] mshi] longValue];
	DAAPResponsemlit *track = [self.results objectAtIndex:(offset + indexPath.row)];
	
	cell.trackName.text = track.minm;
	NSString *album = track.asal;
	NSString *artist = track.asar;
	cell.artistName.text = artist;
	cell.albumName.text = album;
	
	int timeMillis = [track.astm intValue];
	int timeSec = timeMillis / 1000;
	
	int totalDays = timeSec / 86400;
    int totalHours = (timeSec / 3600) - (totalDays * 24);
    int totalMinutes = (timeSec / 60) - (totalDays * 24 * 60) - (totalHours * 60);
    int totalSeconds = timeSec % 60;
		
	cell.trackLength.text = [NSString stringWithFormat:@"%d:%02d",totalMinutes,totalSeconds];
	
	if ([cell.trackName.text isEqualToString:self.currentTrack] && [cell.artistName.text isEqualToString:self.currentArtist] && [cell.albumName.text isEqualToString:self.currentAlbum]) {
		cell.trackName.textColor = [UIColor blueColor];
	} else {
		cell.trackName.textColor = [UIColor blackColor];
	}
	int res = indexPath.row % 2;
	if (res != 0){
		cell.background.backgroundColor = cellColoredBackground;
	} else {
		cell.background.backgroundColor = [UIColor whiteColor];
	}

    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	DAAPResponsemlit *mlit = (DAAPResponsemlit *)[self.indexList objectAtIndex:indexPath.section];
	long offset = [mlit.mshi longValue];
	long i = offset + indexPath.row;
	[[[SessionManager sharedSessionManager] currentServer] playSongInLibrary:i];
    [delegate didSelectItem];
}

// Used to update nowPlaying in the table
- (void) statusUp:(NSNotification *)notification{
	DAAPResponsecmst *cmst = (DAAPResponsecmst *)[notification.userInfo objectForKey:@"cmst"];
	self.currentTrack = cmst.cann;
	self.currentArtist = cmst.cana;
	self.currentAlbum = cmst.canl;

	/*[NSIndexPath indexPathForRow:<#(NSUInteger)row#> inSection:<#(NSUInteger)section#>
	[self.tableView scrollToRowAtIndexPath:[reloadTracks objectAtIndex:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];*/

	[self.tableView reloadData];
}


- (void) display{
	NSLog(@"requesting ALL TRACKS");
	[[[SessionManager sharedSessionManager] currentServer] getAllTracks:self];
}

#pragma mark -
#pragma mark DAAPRequestDelegate methods

- (void) didFinishLoading:(DAAPResponse *)response{
	self.results = [[(DAAPResponseapso *)response mlcl] list];
	self.indexList = [[(DAAPResponseapso *)response mshl] indexList];
	[self.tableView reloadData];
	[self.delegate didFinishLoading];
}

- (void) changeToTrackView{
	[self.navigationController popToRootViewControllerAnimated:NO];
	self.tableView.dataSource = self;
	self.tableView.delegate = self;
	
	[self.tableView reloadData];
}

- (void) changeToArtistView{
	[self.navigationController popToRootViewControllerAnimated:NO];
	if (self.artistDatasource == nil) {
		ArtistDatasource *d = [[ArtistDatasource alloc] init];
		self.artistDatasource = d;
		self.artistDatasource.navigationController = self.navigationController;
		[d release];
	}
	self.tableView.dataSource = self.artistDatasource;
	self.tableView.delegate = self.artistDatasource;
	 
	[self.tableView reloadData];
}

- (void) changeToAlbumView{
	[self.navigationController popToRootViewControllerAnimated:NO];
	DAAPResponseagal * resp = [[[SessionManager sharedSessionManager] currentServer] getAllAlbums];
	AlbumsOfArtistController * c = [[AlbumsOfArtistController alloc] init];
	c.agal = resp;
	[self.navigationController setNavigationBarHidden:NO animated:NO];
	[c setTitle:@"Albums"];
	[self.navigationController pushViewController:c animated:YES];
	[c release];
	
	[self.tableView reloadData];
}
	 

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
	[results release];
	[indexList release];
	[currentTrack release];
	[currentAlbum release];
	[currentArtist release];
	[artistDatasource release];
    [super dealloc];
}


@end

