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
        fit(@"creates file for the note", ^{
            NSString *basePath = @"/tmp/MARK_NOTES_TEST";
            [defaults setObject:basePath forKey:@"filesystemPath"];
            service = [[MKFileSystemSyncService alloc] initWithContext:context];
            
            // Set up test path
            [manager createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:NULL];
            
            // Create a test note
            MKNote *note = [MKNote createEntity];
            note.title = @"foo";
            note.content = @"foo bar";
            [context save:NULL];
            
            NSString *path = [basePath stringByAppendingPathComponent:@"foo.md"];
            expect([manager fileExistsAtPath:path]).to.beTruthy();

            
            
        });
    });
});

SpecEnd