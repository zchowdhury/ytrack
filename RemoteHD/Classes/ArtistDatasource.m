//
//  ArtistDelegate.m
//  RemoteHD
//
//  Created by Fabrice Dewasmes on 11/06/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ArtistDatasource.h"
#import "SessionManager.h"
#import "DAAPResponsemlit.h"
#import "AlbumsOfArtistController.h"
#import "TracksForAlbumController.h"


@implementation ArtistDatasource
@synthesize list;
@synthesize indexList;
@synthesize navigationController;



- (id) init{
	if ((self = [super init])) {
        NSDictionary *result = [[[SessionManager sharedSessionManager] currentServer] getArtists];
		self.list = [result objectForKey:@"list"];
		self.indexList = [result objectForKey:@"index"];
    }
    return self;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.indexList count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	long res = [[(DAAPResponsemlit *)[self.indexList objectAtIndex:section] mshn] longValue];
	
	return res;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	NSMutableArray *chars = [[[NSMutableArray alloc] init] autorelease];
	for (DAAPResponsemlit *mlit in self.indexList) {
		[chars addObject:[mlit mshc]];
	}
	return chars;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
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
	
	return [(DAAPResponsemlit *)[self.indexList objectAtIndex:section] mshc];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	static NSString *CellIdentifier = @"CellArtist";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
	long offset = [[(DAAPResponsemlit *)[self.indexList objectAtIndex:indexPath.section] mshi] longValue];
	NSString *artist = [self.list objectAtIndex:(offset + indexPath.row)];
	
//	NSString *artist = [self.list objectAtIndex:indexPath.row];
	
	cell.textLabel.text = artist;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	DAAPResponsemlit *mlit = (DAAPResponsemlit *)[self.indexList objectAtIndex:indexPath.section];
	long offset = [mlit.mshi longValue];
	long i = offset + indexPath.row;
	NSString *artist = [self.list objectAtIndex:i];
	DAAPResponseagal * resp = [[[SessionManager sharedSessionManager] currentServer] getAlbumsForArtist:artist];
	
	if ([resp.mlcl.list count] == 0) {
		// No named album for that artist
		//TODO use header view to place a 'all tracks' in case some tracks are in an album and others don't
		DAAPResponseapso * resp2 = [[[SessionManager sharedSessionManager] currentServer] getAllTracksForArtist:artist];
		TracksForAlbumController * c = [[TracksForAlbumController alloc] init];
		c.tracks = resp2.mlcl.list;
		[self.navigationController setNavigationBarHidden:NO animated:NO];
		[c setTitle:@"Pistes"];
		c.shouldPlayAllTracks = YES;
		[self.navigationController pushViewController:c animated:YES];
		[c release];
		
	} else if ([resp.mlcl.list count] == 1) {
		long long albumId = [[(DAAPResponsemlit *)[resp.mlcl.list objectAtIndex:0] mper] longLongValue];
		NSLog(@"%qi");
		DAAPResponseapso * resp = [[[SessionManager sharedSessionManager] currentServer] getTracksForAlbum:[NSString stringWithFormat:@"%qi",albumId]];
		TracksForAlbumController * c = [[TracksForAlbumController alloc] init];
		c.tracks = resp.mlcl.list;
		c.shouldPlayAllTracks = NO;
		[self.navigationController setNavigationBarHidden:NO animated:NO];
		[c setTitle:[(DAAPResponsemlit *)[resp.mlcl.list objectAtIndex:0] minm]];
		c.albumName = [(DAAPResponsemlit *)[resp.mlcl.list objectAtIndex:0] minm];
		[self.navigationController pushViewController:c animated:YES];
		[c release];
	}
	
	else {
		AlbumsOfArtistController * c = [[AlbumsOfArtistController alloc] init];
		c.agal = resp;
		[self.navigationController setNavigationBarHidden:NO animated:NO];
		[c setTitle:@"Albums"];
		[self.navigationController pushViewController:c animated:YES];
		[c release];
	}
}

- (void)dealloc {
	[self.list release];
	[self.indexList release];
    [super dealloc];
}

@end
