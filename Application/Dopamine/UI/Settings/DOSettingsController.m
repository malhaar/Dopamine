//
//  DOSettingsController.m
//  Dopamine
//
//  Created by tomt000 on 08/01/2024.
//

#import "DOSettingsController.h"
#import <objc/runtime.h>
#import <libjailbreak/util.h>
#import "DOUIManager.h"
#import "DOPkgManagerPickerViewController.h"
#import "DOHeaderCell.h"
#import "DOEnvironmentManager.h"
#import "DOExploitManager.h"
#import "DOPSListItemsController.h"
#import "DOThemeManager.h"
#import "DOSceneDelegate.h"


@interface DOSettingsController ()

@end

@implementation DOSettingsController

- (void)viewDidLoad
{
    _lastKnownTheme = [[DOThemeManager sharedInstance] enabledTheme].key;
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)arg1
{
    [super viewWillAppear:arg1];
    if (_lastKnownTheme != [[DOThemeManager sharedInstance] enabledTheme].key)
    {
        [DOSceneDelegate relaunch];
        NSString *icon = [[DOThemeManager sharedInstance] enabledTheme].icon;
        [[UIApplication sharedApplication] setAlternateIconName:icon completionHandler:^(NSError * _Nullable error) {
            if (error)
                NSLog(@"Error changing app icon: %@", error);
        }];
    }
}

- (NSArray *)availableKernelExploitIdentifiers
{
    NSMutableArray *identifiers = [NSMutableArray new];
    for (DOExploit *exploit in _availableKernelExploits) {
        [identifiers addObject:exploit.identfier];
    }
    return identifiers;
}

- (NSArray *)availableKernelExploitNames
{
    NSMutableArray *names = [NSMutableArray new];
    for (DOExploit *exploit in _availableKernelExploits) {
        [names addObject:exploit.name];
    }
    return names;
}

- (NSArray *)availablePACBypassIdentifiers
{
    NSMutableArray *identifiers = [NSMutableArray new];
    for (DOExploit *exploit in _availablePACBypasses) {
        [identifiers addObject:exploit.identfier];
    }
    if (![DOEnvironmentManager sharedManager].isPACBypassRequired) {
        [identifiers addObject:@"none"];
    }
    return identifiers;
}

- (NSArray *)availablePACBypassNames
{
    NSMutableArray *names = [NSMutableArray new];
    for (DOExploit *exploit in _availablePACBypasses) {
        [names addObject:exploit.name];
    }
    if (![DOEnvironmentManager sharedManager].isPACBypassRequired) {
        [names addObject:@"None"];
    }
    return names;
}

- (NSArray *)availablePPLBypassIdentifiers
{
    NSMutableArray *identifiers = [NSMutableArray new];
    for (DOExploit *exploit in _availablePPLBypasses) {
        [identifiers addObject:exploit.identfier];
    }
    return identifiers;
}

- (NSArray *)availablePPLBypassNames
{
    NSMutableArray *names = [NSMutableArray new];
    for (DOExploit *exploit in _availablePPLBypasses) {
        [names addObject:exploit.name];
    }
    return names;
}

- (NSArray *)themeIdentifiers
{
    return [[DOThemeManager sharedInstance] getAvailableThemeKeys];
}

- (NSArray *)themeNames
{
    return [[DOThemeManager sharedInstance] getAvailableThemeNames];
}

- (id)specifiers
{
    if(_specifiers == nil) {
        NSMutableArray *specifiers = [NSMutableArray new];
        DOEnvironmentManager *envManager = [DOEnvironmentManager sharedManager];
        DOExploitManager *exploitManager = [DOExploitManager sharedManager];
        
        SEL defGetter = @selector(readPreferenceValue:);
        SEL defSetter = @selector(setPreferenceValue:specifier:);
        
        _availableKernelExploits = [exploitManager availableExploitsForType:EXPLOIT_TYPE_KERNEL].allObjects;
        if (envManager.isArm64e) {
            _availablePACBypasses = [exploitManager availableExploitsForType:EXPLOIT_TYPE_PAC].allObjects;
            _availablePPLBypasses = [exploitManager availableExploitsForType:EXPLOIT_TYPE_PPL].allObjects;
        }
        
        PSSpecifier *headerSpecifier = [PSSpecifier emptyGroupSpecifier];
        [headerSpecifier setProperty:@"DOHeaderCell" forKey:@"headerCellClass"];
        [headerSpecifier setProperty:[NSString stringWithFormat:@"Settings"] forKey:@"title"];
        [specifiers addObject:headerSpecifier];
        
        if (!envManager.isJailbroken) {
            PSSpecifier *exploitGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
            exploitGroupSpecifier.name = NSLocalizedString(@"Section_Exploits", nil);
            [specifiers addObject:exploitGroupSpecifier];
            
            PSSpecifier *kernelExploitSpecifier = [PSSpecifier preferenceSpecifierNamed:NSLocalizedString(@"Kernel Exploit", nil) target:self set:defSetter get:defGetter detail:nil cell:PSLinkListCell edit:nil];
            [kernelExploitSpecifier setProperty:@YES forKey:@"enabled"];
            [kernelExploitSpecifier setProperty:exploitManager.preferredKernelExploit.identfier forKey:@"default"];
            kernelExploitSpecifier.detailControllerClass = [DOPSListItemsController class];
            [kernelExploitSpecifier setProperty:@"availableKernelExploitIdentifiers" forKey:@"valuesDataSource"];
            [kernelExploitSpecifier setProperty:@"availableKernelExploitNames" forKey:@"titlesDataSource"];
            [kernelExploitSpecifier setProperty:@"selectedKernelExploit" forKey:@"key"];
            [specifiers addObject:kernelExploitSpecifier];
            
            if (envManager.isArm64e) {
                PSSpecifier *pacBypassSpecifier = [PSSpecifier preferenceSpecifierNamed:NSLocalizedString(@"PAC Bypass", nil) target:self set:defSetter get:defGetter detail:nil cell:PSLinkListCell edit:nil];
                [pacBypassSpecifier setProperty:@YES forKey:@"enabled"];
                DOExploit *preferredPACBypass = exploitManager.preferredPACBypass;
                if (!preferredPACBypass) {
                    [pacBypassSpecifier setProperty:@"none" forKey:@"default"];
                }
                else {
                    [pacBypassSpecifier setProperty:preferredPACBypass.identfier forKey:@"default"];
                }
                pacBypassSpecifier.detailControllerClass = [DOPSListItemsController class];
                [pacBypassSpecifier setProperty:@"availablePACBypassIdentifiers" forKey:@"valuesDataSource"];
                [pacBypassSpecifier setProperty:@"availablePACBypassNames" forKey:@"titlesDataSource"];
                [pacBypassSpecifier setProperty:@"selectedPACBypass" forKey:@"key"];
                [specifiers addObject:pacBypassSpecifier];
                
                PSSpecifier *pplBypassSpecifier = [PSSpecifier preferenceSpecifierNamed:NSLocalizedString(@"PPL Bypass", nil) target:self set:defSetter get:defGetter detail:nil cell:PSLinkListCell edit:nil];
                [pplBypassSpecifier setProperty:@YES forKey:@"enabled"];
                [pplBypassSpecifier setProperty:exploitManager.preferredPPLBypass.identfier forKey:@"default"];
                pplBypassSpecifier.detailControllerClass = [DOPSListItemsController class];
                [pplBypassSpecifier setProperty:@"availablePPLBypassIdentifiers" forKey:@"valuesDataSource"];
                [pplBypassSpecifier setProperty:@"availablePPLBypassNames" forKey:@"titlesDataSource"];
                [pplBypassSpecifier setProperty:@"selectedPPLBypass" forKey:@"key"];
                [specifiers addObject:pplBypassSpecifier];
            }
        }
        
        PSSpecifier *settingsGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
        settingsGroupSpecifier.name = NSLocalizedString(@"Section_Jailbreak_Settings", nil);
        [specifiers addObject:settingsGroupSpecifier];
        
        PSSpecifier *tweakInjectionSpecifier = [PSSpecifier preferenceSpecifierNamed:NSLocalizedString(@"Settings_Tweak_Injection", nil) target:self set:@selector(setTweakInjectionEnabled:specifier:) get:@selector(readTweakInjectionEnabled:) detail:nil cell:PSSwitchCell edit:nil];
        [tweakInjectionSpecifier setProperty:@YES forKey:@"enabled"];
        [tweakInjectionSpecifier setProperty:@"tweakInjectionEnabled" forKey:@"key"];
        [tweakInjectionSpecifier setProperty:@YES forKey:@"default"];
        [specifiers addObject:tweakInjectionSpecifier];
        
        if (!envManager.isJailbroken) {
            PSSpecifier *verboseLogSpecifier = [PSSpecifier preferenceSpecifierNamed:NSLocalizedString(@"Settings_Verbose_Logs", nil) target:self set:defSetter get:defGetter detail:nil cell:PSSwitchCell edit:nil];
            [verboseLogSpecifier setProperty:@YES forKey:@"enabled"];
            [verboseLogSpecifier setProperty:@"verboseLogsEnabled" forKey:@"key"];
            [verboseLogSpecifier setProperty:@NO forKey:@"default"];
            [specifiers addObject:verboseLogSpecifier];
        }
        
        PSSpecifier *idownloadSpecifier = [PSSpecifier preferenceSpecifierNamed:NSLocalizedString(@"Settings_iDownload", nil) target:self set:@selector(setIDownloadEnabled:specifier:) get:@selector(readIDownloadEnabled:) detail:nil cell:PSSwitchCell edit:nil];
        [idownloadSpecifier setProperty:@YES forKey:@"enabled"];
        [idownloadSpecifier setProperty:@"idownloadEnabled" forKey:@"key"];
        [idownloadSpecifier setProperty:@NO forKey:@"default"];
        [specifiers addObject:idownloadSpecifier];
        
        if (!envManager.isJailbroken && !envManager.isInstalledThroughTrollStore) {
            PSSpecifier *removeJailbreakSwitchSpecifier = [PSSpecifier preferenceSpecifierNamed:NSLocalizedString(@"Button_Remove_Jailbreak", nil) target:self set:@selector(setRemoveJailbreakEnabled:specifier:) get:defGetter detail:nil cell:PSSwitchCell edit:nil];
            [removeJailbreakSwitchSpecifier setProperty:@YES forKey:@"enabled"];
            [removeJailbreakSwitchSpecifier setProperty:@"removeJailbreakEnabled" forKey:@"key"];
            [specifiers addObject:removeJailbreakSwitchSpecifier];
        }
        
        if (envManager.isJailbroken || (envManager.isInstalledThroughTrollStore && envManager.isBootstrapped)) {
            PSSpecifier *actionsGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
            actionsGroupSpecifier.name = NSLocalizedString(@"Section_Actions", nil);
            [specifiers addObject:actionsGroupSpecifier];
            
            if (envManager.isJailbroken) {
                PSSpecifier *reinstallPackageManagersSpecifier = [PSSpecifier emptyGroupSpecifier];
                reinstallPackageManagersSpecifier.target = self;
                [reinstallPackageManagersSpecifier setProperty:@"Button_Reinstall_Package_Managers" forKey:@"title"];
                [reinstallPackageManagersSpecifier setProperty:@"DOButtonCell" forKey:@"headerCellClass"];
                if (@available(iOS 16.0, *))
                    [reinstallPackageManagersSpecifier setProperty:@"shippingbox.and.arrow.backward" forKey:@"image"];
                else
                    [reinstallPackageManagersSpecifier setProperty:@"shippingbox" forKey:@"image"];
                [reinstallPackageManagersSpecifier setProperty:@"reinstallPackageManagersPressed" forKey:@"action"];
                [specifiers addObject:reinstallPackageManagersSpecifier];
                
                PSSpecifier *refreshAppsSpecifier = [PSSpecifier emptyGroupSpecifier];
                refreshAppsSpecifier.target = self;
                [refreshAppsSpecifier setProperty:@"Button_Refresh_Jailbreak_Apps" forKey:@"title"];
                [refreshAppsSpecifier setProperty:@"DOButtonCell" forKey:@"headerCellClass"];
                [refreshAppsSpecifier setProperty:@"arrow.triangle.2.circlepath" forKey:@"image"];
                [refreshAppsSpecifier setProperty:@"refreshJailbreakAppsPressed" forKey:@"action"];
                [specifiers addObject:refreshAppsSpecifier];
            }
            if ((envManager.isJailbroken || envManager.isInstalledThroughTrollStore) && envManager.isBootstrapped) {
                PSSpecifier *hideUnhideJailbreakSpecifier = [PSSpecifier emptyGroupSpecifier];
                hideUnhideJailbreakSpecifier.target = self;
                [hideUnhideJailbreakSpecifier setProperty:@"DOButtonCell" forKey:@"headerCellClass"];
                if (envManager.isJailbreakHidden) {
                    [hideUnhideJailbreakSpecifier setProperty:@"Button_Unhide_Jailbreak" forKey:@"title"];
                    [hideUnhideJailbreakSpecifier setProperty:@"eye" forKey:@"image"];
                }
                else {
                    [hideUnhideJailbreakSpecifier setProperty:@"Button_Hide_Jailbreak" forKey:@"title"];
                    [hideUnhideJailbreakSpecifier setProperty:@"eye.slash" forKey:@"image"];
                }
                [hideUnhideJailbreakSpecifier setProperty:@"hideUnhideJailbreakPressed" forKey:@"action"];
                BOOL hideJailbreakButtonShown = (envManager.isJailbroken || (envManager.isInstalledThroughTrollStore && envManager.isBootstrapped && !envManager.isJailbreakHidden));
                if (hideJailbreakButtonShown) {
                    [specifiers addObject:hideUnhideJailbreakSpecifier];
                }
                
                PSSpecifier *removeJailbreakSpecifier = [PSSpecifier emptyGroupSpecifier];
                removeJailbreakSpecifier.target = self;
                [removeJailbreakSpecifier setProperty:@"Button_Remove_Jailbreak" forKey:@"title"];
                [removeJailbreakSpecifier setProperty:@"DOButtonCell" forKey:@"headerCellClass"];
                [removeJailbreakSpecifier setProperty:@"trash" forKey:@"image"];
                [removeJailbreakSpecifier setProperty:@"removeJailbreakPressed" forKey:@"action"];
                if (hideJailbreakButtonShown) {
                    if (envManager.isJailbroken) {
                        [removeJailbreakSpecifier setProperty:NSLocalizedString(@"Hint_Hide_Jailbreak_Jailbroken", nil) forKey:@"footerText"];
                    }
                    else {
                        [removeJailbreakSpecifier setProperty:NSLocalizedString(@"Hint_Hide_Jailbreak", nil) forKey:@"footerText"];
                    }
                }
                [specifiers addObject:removeJailbreakSpecifier];
            }
        }
        
        PSSpecifier *themingGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
        themingGroupSpecifier.name = NSLocalizedString(@"Section_Customization", nil);
        [specifiers addObject:themingGroupSpecifier];
        
        PSSpecifier *themeSpecifier = [PSSpecifier preferenceSpecifierNamed:NSLocalizedString(@"Theme", nil) target:self set:defSetter get:defGetter detail:nil cell:PSLinkListCell edit:nil];
        themeSpecifier.detailControllerClass = [DOPSListItemsController class];
        [themeSpecifier setProperty:@YES forKey:@"enabled"];
        [themeSpecifier setProperty:@"theme" forKey:@"key"];
        [themeSpecifier setProperty:[[self themeIdentifiers] firstObject] forKey:@"default"];
        [themeSpecifier setProperty:@"themeIdentifiers" forKey:@"valuesDataSource"];
        [themeSpecifier setProperty:@"themeNames" forKey:@"titlesDataSource"];
        [specifiers addObject:themeSpecifier];
        
        _specifiers = specifiers;
    }
    return _specifiers;
}

#pragma mark - Getters & Setters

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier
{
    NSString *key = [specifier propertyForKey:@"key"];
    [[DOPreferenceManager sharedManager] setPreferenceValue:value forKey:key];
}

- (id)readPreferenceValue:(PSSpecifier*)specifier
{
    NSString *key = [specifier propertyForKey:@"key"];
    id value = [[DOPreferenceManager sharedManager] preferenceValueForKey:key];
    if (!value) {
        return [specifier propertyForKey:@"default"];
    }
    return value;
}

- (id)readIDownloadEnabled:(PSSpecifier *)specifier
{
    DOEnvironmentManager *envManager = [DOEnvironmentManager sharedManager];
    if (envManager.isJailbroken) {
        return @([DOEnvironmentManager sharedManager].isIDownloadEnabled);
    }
    return [self readPreferenceValue:specifier];
}

- (void)setIDownloadEnabled:(id)value specifier:(PSSpecifier *)specifier
{
    [self setPreferenceValue:value specifier:specifier];
    DOEnvironmentManager *envManager = [DOEnvironmentManager sharedManager];
    if (envManager.isJailbroken) {
        [[DOEnvironmentManager sharedManager] setIDownloadEnabled:((NSNumber *)value).boolValue];
    }
}

- (id)readTweakInjectionEnabled:(PSSpecifier *)specifier
{
    DOEnvironmentManager *envManager = [DOEnvironmentManager sharedManager];
    if (envManager.isJailbroken) {
        return @([DOEnvironmentManager sharedManager].isTweakInjectionEnabled);
    }
    return [self readPreferenceValue:specifier];
}

- (void)setTweakInjectionEnabled:(id)value specifier:(PSSpecifier *)specifier
{
    [self setPreferenceValue:value specifier:specifier];
    DOEnvironmentManager *envManager = [DOEnvironmentManager sharedManager];
    if (envManager.isJailbroken) {
        [[DOEnvironmentManager sharedManager] setTweakInjectionEnabled:((NSNumber *)value).boolValue];
        UIAlertController *userspaceRebootAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Alert_Tweak_Injection_Toggled_Title", nil) message:NSLocalizedString(@"Alert_Tweak_Injection_Toggled_Body", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *rebootNowAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Alert_Tweak_Injection_Toggled_Reboot_Now", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[DOEnvironmentManager sharedManager] rebootUserspace];
        }];
        UIAlertAction *rebootLaterAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Alert_Tweak_Injection_Toggled_Reboot_Later", nil) style:UIAlertActionStyleCancel handler:nil];
        
        [userspaceRebootAlertController addAction:rebootNowAction];
        [userspaceRebootAlertController addAction:rebootLaterAction];
        [self presentViewController:userspaceRebootAlertController animated:YES completion:nil];
    }
}

- (void)setRemoveJailbreakEnabled:(id)value specifier:(PSSpecifier *)specifier
{
    [self setPreferenceValue:value specifier:specifier];
    if (((NSNumber *)value).boolValue) {
        UIAlertController *confirmationAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Alert_Remove_Jailbreak_Title", nil) message:NSLocalizedString(@"Alert_Remove_Jailbreak_Enabled_Body", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *uninstallAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Button_Continue", nil) style:UIAlertActionStyleDestructive handler:nil];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Button_Cancel", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self setPreferenceValue:@NO specifier:specifier];
            [self reloadSpecifiers];
        }];
        [confirmationAlertController addAction:uninstallAction];
        [confirmationAlertController addAction:cancelAction];
        [self presentViewController:confirmationAlertController animated:YES completion:nil];
    }
}

#pragma mark - Button Actions

- (void)reinstallPackageManagersPressed
{
    [self.navigationController pushViewController:[[DOPkgManagerPickerViewController alloc] init] animated:YES];
}

- (void)refreshJailbreakAppsPressed
{
    [[DOEnvironmentManager sharedManager] refreshJailbreakApps];
}

- (void)hideUnhideJailbreakPressed
{
    DOEnvironmentManager *envManager = [DOEnvironmentManager sharedManager];
    [envManager setJailbreakHidden:!envManager.isJailbreakHidden];
    [self reloadSpecifiers];
}

- (void)removeJailbreakPressed
{
    UIAlertController *confirmationAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Alert_Remove_Jailbreak_Title", nil) message:NSLocalizedString(@"Alert_Remove_Jailbreak_Pressed_Body", nil) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *uninstallAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Button_Continue", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[DOEnvironmentManager sharedManager] deleteBootstrap];
        if ([DOEnvironmentManager sharedManager].isJailbroken) {
            [[DOEnvironmentManager sharedManager] reboot];
        }
        else {
            if (gSystemInfo.jailbreakInfo.rootPath) {
                free(gSystemInfo.jailbreakInfo.rootPath);
                gSystemInfo.jailbreakInfo.rootPath = NULL;
                [[DOEnvironmentManager sharedManager] locateJailbreakRoot];
            }
            [self reloadSpecifiers];
        }
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Button_Cancel", nil) style:UIAlertActionStyleDefault handler:nil];
    [confirmationAlertController addAction:uninstallAction];
    [confirmationAlertController addAction:cancelAction];
    [self presentViewController:confirmationAlertController animated:YES completion:nil];
}

- (void)resetSettingsPressed
{
    [[DOUIManager sharedInstance] resetSettings];
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self reloadSpecifiers];
}


@end
