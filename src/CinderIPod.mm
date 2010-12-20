#include "CinderIPod.h"

namespace cinder { namespace ipod {


// TRACK

Track::Track()
{
}
Track::Track(MPMediaItem *_media_item)
{
    media_item = [_media_item retain];
}
Track::~Track()
{
}

string Track::getTitle()
{
    return string([[media_item valueForProperty: MPMediaItemPropertyTitle] UTF8String]);
}
string Track::getArtist()
{
    return string([[media_item valueForProperty: MPMediaItemPropertyArtist] UTF8String]);
}

Surface Track::getArtwork(const Vec2i &size)
{
    MPMediaItemArtwork *artwork = [media_item valueForProperty: MPMediaItemPropertyArtwork];
    UIImage *artwork_img = [artwork imageWithSize: CGSizeMake(size.x, size.y)];

    if(artwork_img)
        return cocoa::convertUiImage(artwork_img, true);
    else
    	return Surface();
}


// PLAYLIST

Playlist::Playlist()
{
}
Playlist::Playlist(MPMediaItemCollection *collection)
{
    NSArray *items = [collection items];
    for(MPMediaItem *item in items){
    	pushTrack(new Track(item));
    }
}
Playlist::~Playlist()
{
}

void Playlist::pushTrack(TrackRef track)
{
    tracks.push_back(track);
}
void Playlist::pushTrack(Track *track)
{
    tracks.push_back(TrackRef(track));
}

MPMediaItemCollection* Playlist::getMediaItemCollection()
{
    NSMutableArray *items = [NSMutableArray array];
    for(Iter it = tracks.begin(); it != tracks.end(); ++it){
    	[items addObject: (*it)->getMediaItem()];
    }
    return [MPMediaItemCollection collectionWithItems:items];
}


// PLAYER

Player::Player()
{
    controller = [[MPMusicPlayerController iPodMusicPlayer] retain];
}
Player::~Player()
{
}

void Player::play(PlaylistRef playlist, const int index)
{
    MPMediaItemCollection *collection = playlist->getMediaItemCollection();

    [controller stop];
	[controller setQueueWithItemCollection: collection];

    if(index > 0 && index < playlist->size())
    	controller.nowPlayingItem = [[collection items] objectAtIndex: index];

    [controller play];
}
void Player::play(PlaylistRef playlist)
{
    play(playlist, 0);
}


// IPOD

PlaylistRef getAllTracks()
{
	MPMediaQuery *query = [MPMediaQuery songsQuery];

    PlaylistRef tracks = PlaylistRef(new Playlist());

    NSArray *items = [query items];
    for(MPMediaItem *item in items){
        tracks->pushTrack(new Track(item));
    }

    return tracks;
}

vector<PlaylistRef> getAlbums()
{
    MPMediaQuery *query = [MPMediaQuery albumsQuery];

    vector<PlaylistRef> albums;

    NSArray *query_groups = [query collections];
    for(MPMediaItemCollection *group in query_groups){
    	PlaylistRef album = PlaylistRef(new Playlist(group));
        album->name = string([[[group representativeItem] valueForProperty: MPMediaItemPropertyAlbumTitle] UTF8String]);
        albums.push_back(album);
    }

    return albums;
}


}}
