/** <title>NSDataLink</title>

   Copyright (C) 1996, 2005 Free Software Foundation, Inc.

   Author: Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2005
   Author: Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include "config.h"
#include <Foundation/NSFileManager.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSData.h>
#include "AppKit/NSDataLink.h"
#include "AppKit/NSDataLinkManager.h"
#include "AppKit/NSPasteboard.h"
#include "AppKit/NSSavePanel.h"
#include "AppKit/NSSelection.h"

// constants
NSString *NSDataLinkFilenameExtension = @"dlink";

@implementation NSDataLink

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSDataLink class])
    {
      // Initial version
      [self setVersion: 0];
    }
}

//
//
// Instance methods
//
// Initializing a Link
//
- (id)initLinkedToFile:(NSString *)filename
{
  if((self = [self init]) != nil)
    {
      NSData *data = [NSData dataWithBytes: [filename cString] length: [filename cStringLength]];
      NSSelection *selection = [NSSelection selectionWithDescriptionData: data];
      ASSIGN(sourceSelection, selection);
    }
  return nil;
}

- (id)initLinkedToSourceSelection:(NSSelection *)selection
			managedBy:(NSDataLinkManager *)linkManager
		  supportingTypes:(NSArray *)newTypes
{
  if((self = [self init]) != nil)
    {
      ASSIGN(sourceSelection,selection);
      ASSIGN(sourceManager,linkManager);
      ASSIGN(types,newTypes);
    }
  return self;
}

- (id)initWithContentsOfFile:(NSString *)filename
{
  NSData *data = AUTORELEASE([[NSData alloc] initWithContentsOfFile: filename]);
  id object = [NSUnarchiver unarchiveObjectWithData: data];
  RELEASE(self);
  return object;
}

- (id)initWithPasteboard:(NSPasteboard *)pasteboard
{
  NSData *data = [pasteboard dataForType: NSDataLinkPboardType];
  id object = [NSUnarchiver unarchiveObjectWithData: data];
  RELEASE(self);
  return object;
}

//
// Exporting a Link
//
- (BOOL)saveLinkIn:(NSString *)directoryName
{
  NSSavePanel		*sp;
  int			result;

  sp = [NSSavePanel savePanel];
  [sp setRequiredFileType: NSDataLinkFilenameExtension];
  result = [sp runModalForDirectory: directoryName file: @""];
  if (result == NSOKButton)
    {
      NSFileManager	*mgr = [NSFileManager defaultManager];
      NSString		*path = [sp filename];

      if ([mgr fileExistsAtPath: path] == YES)
	{
	  /* NSSavePanel has already asked if it's ok to replace */
	  NSString	*bPath = [path stringByAppendingString: @"~"];
	  
	  [mgr removeFileAtPath: bPath handler: nil];
	  [mgr movePath: path toPath: bPath handler: nil];
	}

      // save it.
      return [self writeToFile: path];
    }
  return NO;
}

- (BOOL)writeToFile:(NSString *)filename
{
  NSString *path = filename;

  if([[path pathExtension] isEqual: NSDataLinkFilenameExtension] == NO)
    {
      path = [filename stringByAppendingPathExtension: NSDataLinkFilenameExtension];
    }

  return [NSArchiver archiveRootObject: self toFile: path];
}

- (void)writeToPasteboard:(NSPasteboard *)pasteboard
{
  NSData *data = [NSArchiver archivedDataWithRootObject: self];
  [pasteboard setData: data forType: NSDataLinkPboardType];
}

//
// Information about the Link
//
- (NSDataLinkDisposition)disposition
{
  return disposition;
}

- (NSDataLinkNumber)linkNumber
{
  return linkNumber;
}

- (NSDataLinkManager *)manager
{
  return sourceManager;
}

//
// Information about the Link's Source
//
- (NSDate *)lastUpdateTime
{
  return lastUpdateTime;
}

- (BOOL)openSource
{
  return NO;
}

- (NSString *)sourceApplicationName
{
  return sourceApplicationName;
}

- (NSString *)sourceFilename
{
  return sourceFilename;
}

- (NSSelection *)sourceSelection
{
  return sourceSelection;
}

- (NSArray *)types
{
  return types;
}

//
// Information about the Link's Destination
//
- (NSString *)destinationApplicationName
{
  return destinationApplicationName;
}

- (NSString *)destinationFilename
{
  return destinationFilename;
}

- (NSSelection *)destinationSelection
{
  return destinationSelection;
}

//
// Changing the Link
//
- (BOOL)break
{
  id srcDelegate = [sourceManager delegate];
  id dstDelegate = [destinationManager delegate];

  // The spec is quite vague here.  I don't know under what 
  // circumstances a link cannot be broken, so this method 
  // always returns YES.

  if([srcDelegate respondsToSelector: @selector(dataLinkManager:didBreakLink:)])
    {
      [srcDelegate dataLinkManager: sourceManager didBreakLink: self];
    }

  if([dstDelegate respondsToSelector: @selector(dataLinkManager:didBreakLink:)])
    {
      [dstDelegate dataLinkManager: destinationManager didBreakLink: self];
    }

  return (_flags.broken = YES);
}

- (void)noteSourceEdited
{
  _flags.isDirty = YES;

  if(updateMode != NSUpdateNever)
    {
      [sourceManager noteDocumentEdited];
    }
}

- (void)setUpdateMode:(NSDataLinkUpdateMode)mode
{
  updateMode = mode;
}

- (BOOL)updateDestination
{
  return NO;
}

- (NSDataLinkUpdateMode)updateMode
{
  return updateMode;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  BOOL flag = NO;

  [aCoder encodeValueOfObjCType: @encode(int) at: &linkNumber];
  [aCoder encodeValueOfObjCType: @encode(int) at: &disposition];
  [aCoder encodeValueOfObjCType: @encode(int) at: &updateMode];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &lastUpdateTime];

  [aCoder encodeValueOfObjCType: @encode(id)  at: &sourceApplicationName];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &sourceFilename];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &sourceSelection];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &sourceManager];

  [aCoder encodeValueOfObjCType: @encode(id)  at: &destinationApplicationName];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &destinationFilename];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &destinationSelection];
  [aCoder encodeValueOfObjCType: @encode(id)  at: &destinationManager];

  [aCoder encodeValueOfObjCType: @encode(id)  at: &types];

  // flags...
  flag = _flags.appVerifies;
  [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
  flag = _flags.canUpdateContinuously;
  [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
  flag = _flags.isDirty;
  [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
  flag = _flags.willOpenSource;
  [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
  flag = _flags.willUpdate;
  [aCoder encodeValueOfObjCType: @encode(BOOL)  at: &flag];
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  int version = [aCoder versionForClassName: @"NSDataLink"];

  if(version == 0)
    {
      BOOL flag = NO;

      [aCoder decodeValueOfObjCType: @encode(int) at: &linkNumber];
      [aCoder decodeValueOfObjCType: @encode(int) at: &disposition];
      [aCoder decodeValueOfObjCType: @encode(int) at: &updateMode];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &sourceManager];
      [aCoder encodeValueOfObjCType: @encode(id)  at: &destinationManager];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &lastUpdateTime];

      [aCoder decodeValueOfObjCType: @encode(id)  at: &sourceApplicationName];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &sourceFilename];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &sourceSelection];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &sourceManager];

      [aCoder decodeValueOfObjCType: @encode(id)  at: &destinationApplicationName];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &destinationFilename];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &destinationSelection];
      [aCoder decodeValueOfObjCType: @encode(id)  at: &destinationManager];

      [aCoder decodeValueOfObjCType: @encode(id)  at: &types];

      // flags...
      [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
      _flags.appVerifies = flag;
      [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
      _flags.canUpdateContinuously = flag;
      [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
      _flags.isDirty = flag;
      [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
      _flags.willOpenSource = flag;
      [aCoder decodeValueOfObjCType: @encode(BOOL)  at: &flag];
      _flags.willUpdate = flag;
    }
  else
    {
      return nil;
    }

  return self;
}

@end
