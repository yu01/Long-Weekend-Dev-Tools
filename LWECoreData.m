//
//  LWECoreData.m
//
//  Created by シャロット ロス on 6/13/10.
//  Copyright 2010 LONG WEEKEND INC. All rights reserved.
//

#import "LWECoreData.h"
#import "LWEDebug.h"

/*!
    @class       LWECoreData
    @discussion
    Implements common data actions as static methods to reduce the amount of Core Data-related code
    that needs to be in the actual source code files.
*/
@implementation LWECoreData

/**
 * Gets all entities for a given entity & context ("SELECT * FROM foo" in SQL)
 * \param entityName Name of the Core Data entity to fetch
 * \param managedObjectContext Which ObjectContext to use
 */
+ (NSArray *) fetchAll:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
  return [LWECoreData fetch:entityName managedObjectContext:managedObjectContext withSortDescriptors:nil predicate:nil];
}


/**
 * Gets all entities for a given entity & context ("SELECT * FROM foo WHERE x ORDER BY y" in SQL)
 * \param entityName Name of the Core Data entity to fetch
 * \param managedObjectContext Which ObjectContext to use
 * \param sortDescriptorsOrNil Sort descriptor, or use nil if you don't want to sort
 * \param predicate the "where clause" of the query
 */
+ (NSArray *) fetch:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)managedObjectContext withSortDescriptors:(NSArray *)sortDescriptorsOrNil predicate:(id)stringOrPredicate, ...
{
  return [LWECoreData fetch:entityName managedObjectContext:managedObjectContext withSortDescriptors:sortDescriptorsOrNil withLimit:0 predicate:stringOrPredicate];
}


/**
 * Gets all entities for a given entity & context ("SELECT * FROM foo WHERE x ORDER BY y LIMIT z" in SQL)
 * \param entityName Name of the Core Data entity to fetch
 * \param managedObjectContext Which ObjectContext to use
 * \param sortDescriptorsOrNil Sort descriptor, or use nil if you don't want to sort
 * \param limitOrNil Integer number to limit by.  0 for no limit clause
 * \param predicate the "where clause" of the query
 */
+ (NSArray *) fetch:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)managedObjectContext withSortDescriptors:(NSArray *)sortDescriptorsOrNil withLimit:(int)limitOrNil predicate:(id)stringOrPredicate, ...
{
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
  [fetchRequest setEntity:entity];
  
  if(limitOrNil > 0)
  {
    [fetchRequest setFetchLimit:limitOrNil];
  }
  
  if (sortDescriptorsOrNil != nil)
  {
    [fetchRequest setSortDescriptors:sortDescriptorsOrNil];
  }
  
  // add the predicate (Apple-speak for where)
  if (stringOrPredicate)
  {
    NSPredicate *predicate;
    if ([stringOrPredicate isKindOfClass:[NSString class]])
    {
      va_list variadicArguments;
      va_start(variadicArguments, stringOrPredicate);
      predicate = [NSPredicate predicateWithFormat:stringOrPredicate
                                         arguments:variadicArguments];
      va_end(variadicArguments);
    }
    else
    {
      NSAssert2([stringOrPredicate isKindOfClass:[NSPredicate class]], @"Second parameter passed to %s is of unexpected class %@", sel_getName(_cmd), [stringOrPredicate class]);
      predicate = (NSPredicate *)stringOrPredicate;
    }
    [fetchRequest setPredicate:predicate];
  }
  
  NSError *error;
  NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
  
  [fetchRequest release]; 
  
  return results;
}

/**
 * Saves the current objectContext
 * \param managedObjectContext The context to save
 * \return YES if successful
 */
+ (BOOL) save:(NSManagedObjectContext *)managedObjectContext
{
  BOOL returnVal = YES;
  NSError *error;
  if (![managedObjectContext save:&error]) 
  {
    NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    if (detailedErrors != nil && [detailedErrors count] > 0)
    {
      for(NSError* detailedError in detailedErrors)
      {
        LWE_LOG(@"  DetailedError: %@", [detailedError userInfo]);
      }
    }
    // Now fail
    NSAssert2(0, @"This is embarrassing. %s We failed to save because: %@", sel_getName(_cmd), [error localizedDescription]);
    returnVal = NO;
  }
  return returnVal;
}

/**
 * Deletes an entity from the current objectContext
 * \param entity Object to delete
 * \param context managedObjectContext to delete from
 * \return returns YES on success, NO on delete failure (swallows exception)
 */
+ (BOOL) delete:(id)entity fromContext:(NSManagedObjectContext *)context
{
	[context deleteObject:entity];
  @try
  {
    [LWECoreData save:context];
  }
  @catch (NSException * e)
  {
    return NO;
  }
  return YES;
}

@end
