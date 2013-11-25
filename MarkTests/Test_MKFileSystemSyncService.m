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
            basePath = @"/tmp/MARK_NOTES_TEST";
            [manager createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:NULL];
            
            service = [[MKFileSystemSyncService alloc] initWithContext:context];
            [defaults setObject:basePath forKey:@"filesystemPath"];
        });
        
        it(@"creates file for the note", ^{
            // Create a test note
            MKNote *note = [MKNote createEntity];
            note.title = @"foo";
            note.content = @"foo bar";
            NSLog(@"Context: %@", context);
            [context save:NULL];
            
            NSString *path = [basePath stringByAppendingPathComponent:@"foo.md"];
            expect([manager fileExistsAtPath:path]).to.beTruthy();
        });
        
        afterAll(^{
            service = nil;
        });
    });
});

SpecEnd