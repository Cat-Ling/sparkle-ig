#import "SPKStrings.h"
#import "SPKDeletedMessagesDate.h"
#import "../../../Utils.h"

@implementation SPKDeletedMessagesDate

+ (NSDateFormatter *)shortFormatter {
    static NSDateFormatter *f;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        f = [NSDateFormatter new];
        f.locale = [SPKUtils spk_activeFormattingLocale];
        f.dateStyle = NSDateFormatterShortStyle;
        f.timeStyle = NSDateFormatterShortStyle;
    });
    return f;
}

+ (NSDateFormatter *)mediumFormatter {
    static NSDateFormatter *f;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        f = [NSDateFormatter new];
        f.locale = [SPKUtils spk_activeFormattingLocale];
        f.dateStyle = NSDateFormatterMediumStyle;
        f.timeStyle = NSDateFormatterShortStyle;
    });
    return f;
}

+ (NSDateFormatter *)dayMonthFormatter {
    static NSDateFormatter *f;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        f = [NSDateFormatter new];
        f.locale = [SPKUtils spk_activeFormattingLocale];
        f.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMd"
                                                       options:0
                                                        locale:f.locale];
    });
    return f;
}

+ (NSDateFormatter *)timeOnlyFormatter {
    static NSDateFormatter *f;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        f = [NSDateFormatter new];
        f.locale = [SPKUtils spk_activeFormattingLocale];
        f.dateStyle = NSDateFormatterNoStyle;
        f.timeStyle = NSDateFormatterShortStyle;
    });
    return f;
}

// Tight relative-time formatter — "now", "Nm ago", "Nh ago", "Nd ago"
// (up to 6 days), otherwise falls back to abbreviated month-day. Today's
// times are shown as the time-only string so the user can tell which
// message is most recent at a glance.
+ (NSString *)relativeStringForDate:(NSDate *)d {
    if (!d)
        return @"";
    NSTimeInterval delta = -[d timeIntervalSinceNow];
    if (delta < 0)
        delta = 0;
    if (delta < 60)
        return SPKL(@"MESSAGES_DELETED_MESSAGES_DATE_NOW_TEXT");
    if (delta < 3600)
        return [NSString stringWithFormat:SPKL(@"MESSAGES_DELETED_MESSAGES_DATE_VALUE_M_AGO_FORMAT"), (int)(delta / 60)];
    if (delta < 86400) {
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDate *startOfToday = [cal startOfDayForDate:[NSDate date]];
        if ([d compare:startOfToday] != NSOrderedAscending) {
            return [[self timeOnlyFormatter] stringFromDate:d];
        }
        return [NSString stringWithFormat:SPKL(@"MESSAGES_DELETED_MESSAGES_DATE_VALUE_H_AGO_FORMAT"), (int)(delta / 3600)];
    }
    if (delta < 86400 * 7)
        return [NSString stringWithFormat:SPKL(@"MESSAGES_DELETED_MESSAGES_DATE_VALUE_D_AGO_FORMAT"), (int)(delta / 86400)];
    return [[self dayMonthFormatter] stringFromDate:d];
}

+ (NSString *)stringForDate:(NSDate *)d {
    if (!d)
        return @"";
    NSString *mode = [SPKUtils getStringPref:@"dm_log_date_format"];
    if (![mode isEqualToString:@"absolute"])
        return [self relativeStringForDate:d];
    return [[self shortFormatter] stringFromDate:d];
}

+ (NSString *)verboseStringForDate:(NSDate *)d {
    if (!d)
        return @"";
    return [[self mediumFormatter] stringFromDate:d];
}

@end
