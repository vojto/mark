#define EXP_SHORTHAND
#import <Specta/Specta.h>
#import <Expecta/Expecta.h>

#import "MKFileSystemSyncService.h"
#import "MKNote.h"

SpecBegin(MKFileSystemSyncService)

describe(@"MKFileSystemSyncService", ^{
    __block MKFileSystemSyncService *service;
    __block NSManagedObjectContext *context;
    __block NSUserDefaults *defaults;
    __block NSFileManager *manager;
    __block NSString *basePath;
    
    beforeAll(^{
        [MagicalRecord setDefaultModelFromClass:[self class]];
        [MagicalRecord setupCoreDataStackWithInMemoryStore];
        context = [NSManagedObjectContext defaultContext];
        defaults = [NSUserDefaults standardUserDefaults];
        manager = [NSFileManager defaultManager];
    });
    
    it(@"loads base path from defaults", ^{
        [defaults setObject:@"test" forKey:@"filesystemPath"];
        service = [[MKFileSystemSyncService alloc] initWithContext:context];
        expect(service.basePath).to.equal(@"test");
        service = nil;
    });
    
    it(@"updates base path after changing defaults", ^{
        service = [[MKFileSystemSyncService alloc] initWithContext:context];
        [defaults setObject:@"test2" forKey:@"filesystemPath"];
        expect(service.basePath).to.equal(@"test2");
        service = nil;
    });
    
    describe(@"syncing with the file system", ^{
        beforeAll(^{
            basePath = @"/Users/vojto/Desktop/MARK_NOTES_TEST";
            [manager createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:NULL];
            [defaults setObject:basePath forKey:@"filesystemPath"];
            service = [[MKFileSystemSyncService alloc] initWithContext:context];
        });
        
        beforeEach(^{
            NSDirectoryEnumerator *enumerator = [manager enumeratorAtPath:basePath];
            NSString *file;
            while(file = [enumerator nextObject]) {
                [manager removeItemAtPath:[basePath stringByAppendingPathComponent:file] error:NULL];
            }
            for (MKNote *note in [MKNote findAll]) {
                [note deleteEntity];
            }
        });
        
        it(@"creates file for the note", ^{
            // Create a test note
            MKNote *note = [MKNote createEntity];
            note.title = @"foo";
            note.content = @"foo bar";
            NSLog(@"Context: %@", context);
            [context save:NULL];
            usleep(100*1000); // wait 0.1s for saving to finish
            NSString *path = [basePath stringByAppendingPathComponent:@"foo.md"];
            expect([manager fileExistsAtPath:path]).to.beTruthy();
        });
        
        it(@"restores note from file", ^{
            NSString *content = @"a note\n\n<!-- Mark: xxx1|tag1 -->";
            [content writeToFile:[basePath stringByAppendingPathComponent:@"restore.md"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
            [service restoreFromFileSystem];
            usleep(300*1000); // wait 0.1s for restoring to finish
            NSArray *notes = [MKNote findAll];
            expect(notes.count).to.equal(1);
        });
        
        it(@"removes note that was removed from disk", ^{
            // First, create 2 notes and sync them to the disk
            MKNote *note1 = [MKNote createEntity];
            note1.title = @"note1";
            MKNote *note2 = [MKNote createEntity];
            note2.title = @"note2";
            [context saveToPersistentStoreAndWait];
            usleep(300*1000);
            
            // Make sure the files were created
            NSString *path = [basePath stringByAppendingPathComponent:@"note1.md"];
            expect([manager fileExistsAtPath:path]).to.beTruthy();
            path = [basePath stringByAppendingPathComponent:@"note2.md"];
            expect([manager fileExistsAtPath:path]).to.beTruthy();

            // Remove one of the files
            [manager removeItemAtPath:[basePath stringByAppendingPathComponent:@"note1.md"] error:NULL];
            
            // Restore from filesystem
            [service restoreFromFileSystem];
            usleep(300*1000);
            
            // Assert that it was removed from Core Data storage
            NSArray *notes = [MKNote findAll];
            expect(notes.count).to.equal(1);
        });
        
        fit(@"removes file after removing note", ^{
            MKNote *note = [MKNote createEntity];
            note.title = @"deleteme";
            [context saveToPersistentStoreAndWait];
            usleep(300*1000);
            
            // Make sure the file exists
            NSString *path = [basePath stringByAppendingPathComponent:@"deleteme.md"];
            expect([manager fileExistsAtPath:path]).to.beTruthy();
            
            // Delete note
            [note deleteEntity];
            [context saveToPersistentStoreAndWait];
            usleep(300*1000);
            
            // Make sure the file was deleted
            expect([manager fileExistsAtPath:path]).to.beFalsy();
            
            // Make sure it won't attempt to delete it again
            expect(service.deletedNotePaths).to.beEmpty();
        });
        
        afterAll(^{
            service = nil;
        });
    });
});

SpecEnd