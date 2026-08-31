#import "SPKStrings.h"
#import "SPKDeletedMessagesModels.h"

NSString *SPKDeletedMessageKindToString(SPKDeletedMessageKind kind) {
    switch (kind) {
    case SPKDeletedMessageKindText:
        return @"text";
    case SPKDeletedMessageKindPhoto:
        return @"photo";
    case SPKDeletedMessageKindVideo:
        return @"video";
    case SPKDeletedMessageKindVoice:
        return @"voice";
    case SPKDeletedMessageKindGif:
        return @"gif";
    case SPKDeletedMessageKindSticker:
        return @"sticker";
    case SPKDeletedMessageKindShare:
        return @"share";
    case SPKDeletedMessageKindLink:
        return @"link";
    case SPKDeletedMessageKindAudioShare:
        return @"audio_share";
    case SPKDeletedMessageKindReaction:
        return @"reaction";
    case SPKDeletedMessageKindOther:
        return @"other";
    case SPKDeletedMessageKindUnknown:
    default:
        return @"unknown";
    }
}

NSString *_Nullable SPKDeletedMessageDisplayBody(SPKDeletedMessage *message) {
    if (!message)
        return nil;
    if (message.kind == SPKDeletedMessageKindReaction) {
        // Composed here rather than read back from `text` so the sentence follows
        // the reader's language instead of whichever one was active at capture.
        NSString *emoji = message.reactionEmoji;
        NSString *target = message.reactionTargetPreview;
        if (!target.length && message.reactionTargetKind != SPKDeletedMessageKindUnknown)
            target = [SPKDeletedMessageKindLocalizedName(message.reactionTargetKind) lowercaseString];
        if (emoji.length && target.length)
            return [NSString stringWithFormat:SPKL(@"MESSAGES_DELETED_MESSAGES_CAPTURE_REMOVED_VALUE_VALUE_FORMAT"), emoji, target];
        if (emoji.length)
            return [NSString stringWithFormat:SPKL(@"MESSAGES_DELETED_MESSAGES_CAPTURE_REMOVED_REACTION_VALUE_ACTION"), emoji];
        // Records written before the emoji was captured still carry a stored body.
        if (!message.text.length && !message.previewText.length)
            return SPKL(@"MESSAGES_DELETED_MESSAGES_CAPTURE_REMOVED_REACTION_ACTION");
    }
    return message.text.length ? message.text : message.previewText;
}

SPKDeletedMessageKind SPKDeletedMessageKindFromString(NSString *s) {
    if (![s isKindOfClass:[NSString class]])
        return SPKDeletedMessageKindUnknown;
    if ([s isEqualToString:@"text"])
        return SPKDeletedMessageKindText;
    if ([s isEqualToString:@"photo"])
        return SPKDeletedMessageKindPhoto;
    if ([s isEqualToString:@"video"])
        return SPKDeletedMessageKindVideo;
    if ([s isEqualToString:@"voice"])
        return SPKDeletedMessageKindVoice;
    if ([s isEqualToString:@"gif"])
        return SPKDeletedMessageKindGif;
    if ([s isEqualToString:@"sticker"])
        return SPKDeletedMessageKindSticker;
    if ([s isEqualToString:@"share"])
        return SPKDeletedMessageKindShare;
    if ([s isEqualToString:@"link"])
        return SPKDeletedMessageKindLink;
    if ([s isEqualToString:@"audio_share"])
        return SPKDeletedMessageKindAudioShare;
    if ([s isEqualToString:@"reaction"])
        return SPKDeletedMessageKindReaction;
    if ([s isEqualToString:@"other"])
        return SPKDeletedMessageKindOther;
    return SPKDeletedMessageKindUnknown;
}

NSString *SPKDeletedMessageKindLocalizedName(SPKDeletedMessageKind kind) {
    switch (kind) {
    case SPKDeletedMessageKindText:
        return SPKL(@"MESSAGES_DELETED_MESSAGES_MODELS_TEXT");
    case SPKDeletedMessageKindPhoto:
        return SPKL(@"COMMON_MEDIA_TYPE_PHOTO");
    case SPKDeletedMessageKindVideo:
        return SPKL(@"COMMON_MEDIA_TYPE_VIDEO");
    case SPKDeletedMessageKindVoice:
        return SPKL(@"MESSAGES_DELETED_MESSAGES_MODELS_VOICE_TEXT");
    case SPKDeletedMessageKindGif:
        return SPKL(@"COMMON_MEDIA_TYPE_GIF");
    case SPKDeletedMessageKindSticker:
        return SPKL(@"COMMON_MEDIA_TYPE_STICKER");
    case SPKDeletedMessageKindShare:
        return SPKL(@"ALERT_ACTION_SHARE");
    case SPKDeletedMessageKindLink:
        return SPKL(@"ACTION_BUTTON_ACTION_DESCRIPTOR_LINK_TEXT");
    case SPKDeletedMessageKindAudioShare:
        return SPKL(@"COMMON_MEDIA_TYPE_AUDIO");
    case SPKDeletedMessageKindReaction:
        return SPKL(@"MESSAGES_DELETED_MESSAGES_MODELS_REACTION_ACTION");
    case SPKDeletedMessageKindOther:
        return SPKL(@"STORIES_OTHER_HEADER");
    case SPKDeletedMessageKindUnknown:
    default:
        return SPKL(@"MESSAGES_DELETED_MESSAGES_MODELS_UNKNOWN_TEXT");
    }
}

NSString *SPKDeletedMessageKindSymbol(SPKDeletedMessageKind kind) {
    return SPKDeletedMessageKindSymbolFilled(kind, NO);
}

NSString *SPKDeletedMessageKindSymbolFilled(SPKDeletedMessageKind kind, BOOL filled) {
    switch (kind) {
    case SPKDeletedMessageKindText:
        return @"message";
    case SPKDeletedMessageKindPhoto:
        return filled ? @"photo_filled" : @"photo";
    case SPKDeletedMessageKindVideo:
        return filled ? @"video_filled" : @"video";
    case SPKDeletedMessageKindVoice:
        return filled ? @"voice_filled" : @"voice";
    case SPKDeletedMessageKindGif:
        return filled ? @"gif_filled" : @"gif";
    case SPKDeletedMessageKindSticker:
        return filled ? @"sticker_filled" : @"sticker";
    case SPKDeletedMessageKindShare:
        return @"share";
    case SPKDeletedMessageKindLink:
        return @"link";
    case SPKDeletedMessageKindAudioShare:
        return @"audio";
    case SPKDeletedMessageKindReaction:
        return @"reactions";
    case SPKDeletedMessageKindOther:
        return @"message";
    case SPKDeletedMessageKindUnknown:
    default:
        return @"message";
    }
}

NSString *SPKDeletedMessageShareSubtypeName(NSString *subtype) {
    if ([subtype isEqualToString:@"reel"])
        return SPKL(@"COMMON_MEDIA_TYPE_REEL");
    if ([subtype isEqualToString:@"post"])
        return SPKL(@"MESSAGES_DELETED_MESSAGES_MODELS_POST_TEXT");
    if ([subtype isEqualToString:@"story"])
        return SPKL(@"COMMON_MEDIA_TYPE_STORY");
    if ([subtype isEqualToString:@"profile"])
        return SPKL(@"PROFILE_TITLE");
    if ([subtype isEqualToString:@"note"])
        return SPKL(@"MESSAGES_DELETED_MESSAGES_MODELS_NOTE_TEXT");
    if ([subtype isEqualToString:@"location"])
        return SPKL(@"MESSAGES_DELETED_MESSAGES_MODELS_LOCATION_TEXT");
    if ([subtype isEqualToString:@"audio"])
        return SPKL(@"COMMON_MEDIA_TYPE_AUDIO");
    return SPKL(@"MESSAGES_DELETED_MESSAGES_MODELS_SHARED_POST_TEXT");
}

NSString *SPKDeletedMessageShareSubtypeSymbol(__unused NSString *subtype) {
    // A shared post is a DM-forwarded post in every case, so use IG's "share to
    // direct" prism glyph for all subtypes.
    return @"ig_icon_direct_prism_filled_12";
}

static NSDate *spkDateFromJSON(id v) {
    if ([v isKindOfClass:[NSNumber class]])
        return [NSDate dateWithTimeIntervalSince1970:[v doubleValue]];
    return nil;
}
static NSNumber *spkDateToJSON(NSDate *d) {
    return d ? @(d.timeIntervalSince1970) : nil;
}
static NSString *spkStr(id v) {
    return [v isKindOfClass:[NSString class]] ? v : nil;
}
static double spkDouble(id v) {
    return [v isKindOfClass:[NSNumber class]] ? [v doubleValue] : 0;
}

@implementation SPKDeletedMessage

+ (instancetype)messageFromJSONDict:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]])
        return nil;
    SPKDeletedMessage *m = [SPKDeletedMessage new];
    m.viewMode = -1;
    m.messageId = spkStr(dict[@"message_id"]);
    m.threadId = spkStr(dict[@"thread_id"]);
    m.threadTitle = spkStr(dict[@"thread_title"]);
    m.isGroup = [dict[@"is_group"] boolValue];
    m.threadPhotoURL = spkStr(dict[@"thread_photo_url"]);
    m.senderPk = spkStr(dict[@"sender_pk"]);
    m.senderUsername = spkStr(dict[@"sender_username"]);
    m.senderFullName = spkStr(dict[@"sender_full_name"]);
    m.senderProfilePicURL = spkStr(dict[@"sender_profile_pic_url"]);
    m.sentAt = spkDateFromJSON(dict[@"sent_at"]);
    m.capturedAt = spkDateFromJSON(dict[@"captured_at"]);
    m.deletedAt = spkDateFromJSON(dict[@"deleted_at"]);
    m.kind = SPKDeletedMessageKindFromString(spkStr(dict[@"kind"]));
    m.text = spkStr(dict[@"text"]);
    m.previewText = spkStr(dict[@"preview"]);
    m.mediaURL = spkStr(dict[@"media_url"]);
    m.mediaPath = spkStr(dict[@"media_path"]);
    m.thumbnailURL = spkStr(dict[@"thumbnail_url"]);
    m.thumbnailPath = spkStr(dict[@"thumbnail_path"]);
    m.mediaMimeType = spkStr(dict[@"media_mime"]);
    if ([dict[@"view_mode"] isKindOfClass:[NSNumber class]])
        m.viewMode = [dict[@"view_mode"] integerValue];
    m.stagedMediaPath = spkStr(dict[@"staged_media_path"]);
    m.stagedThumbnailPath = spkStr(dict[@"staged_thumbnail_path"]);
    m.mediaURLStaleAt = spkDateFromJSON(dict[@"media_url_stale_at"]);
    m.durationSeconds = spkDouble(dict[@"duration"]);
    id wf = dict[@"waveform"];
    if ([wf isKindOfClass:[NSArray class]])
        m.waveform = wf;
    m.width = spkDouble(dict[@"width"]);
    m.height = spkDouble(dict[@"height"]);
    m.replyToMessageId = spkStr(dict[@"reply_to_id"]);
    m.reactionEmoji = spkStr(dict[@"reaction_emoji"]);
    m.reactionTargetPreview = spkStr(dict[@"reaction_target"]);
    // Absent on records written before the field existed, which decode to
    // Unknown and keep falling back to their stored body.
    m.reactionTargetKind = SPKDeletedMessageKindFromString(spkStr(dict[@"reaction_target_kind"]));
    m.shareSubtype = spkStr(dict[@"share_subtype"]);
    m.shareAuthor = spkStr(dict[@"share_author"]);
    if (!m.messageId.length || !m.senderPk.length)
        return nil;
    return m;
}

- (NSDictionary *)toJSONDict {
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    if (self.messageId)
        d[@"message_id"] = self.messageId;
    if (self.threadId)
        d[@"thread_id"] = self.threadId;
    if (self.threadTitle.length)
        d[@"thread_title"] = self.threadTitle;
    if (self.isGroup)
        d[@"is_group"] = @YES;
    if (self.threadPhotoURL.length)
        d[@"thread_photo_url"] = self.threadPhotoURL;
    if (self.senderPk)
        d[@"sender_pk"] = self.senderPk;
    if (self.senderUsername)
        d[@"sender_username"] = self.senderUsername;
    if (self.senderFullName)
        d[@"sender_full_name"] = self.senderFullName;
    if (self.senderProfilePicURL)
        d[@"sender_profile_pic_url"] = self.senderProfilePicURL;
    if (self.sentAt)
        d[@"sent_at"] = spkDateToJSON(self.sentAt);
    if (self.capturedAt)
        d[@"captured_at"] = spkDateToJSON(self.capturedAt);
    if (self.deletedAt)
        d[@"deleted_at"] = spkDateToJSON(self.deletedAt);
    d[@"kind"] = SPKDeletedMessageKindToString(self.kind);
    if (self.text.length)
        d[@"text"] = self.text;
    if (self.previewText.length)
        d[@"preview"] = self.previewText;
    if (self.mediaURL)
        d[@"media_url"] = self.mediaURL;
    if (self.mediaPath)
        d[@"media_path"] = self.mediaPath;
    if (self.thumbnailURL)
        d[@"thumbnail_url"] = self.thumbnailURL;
    if (self.thumbnailPath)
        d[@"thumbnail_path"] = self.thumbnailPath;
    if (self.mediaMimeType)
        d[@"media_mime"] = self.mediaMimeType;
    if (self.viewMode >= 0)
        d[@"view_mode"] = @(self.viewMode);
    if (self.stagedMediaPath)
        d[@"staged_media_path"] = self.stagedMediaPath;
    if (self.stagedThumbnailPath)
        d[@"staged_thumbnail_path"] = self.stagedThumbnailPath;
    if (self.mediaURLStaleAt)
        d[@"media_url_stale_at"] = spkDateToJSON(self.mediaURLStaleAt);
    if (self.durationSeconds > 0)
        d[@"duration"] = @(self.durationSeconds);
    if (self.waveform.count)
        d[@"waveform"] = self.waveform;
    if (self.width > 0)
        d[@"width"] = @(self.width);
    if (self.height > 0)
        d[@"height"] = @(self.height);
    if (self.replyToMessageId.length)
        d[@"reply_to_id"] = self.replyToMessageId;
    if (self.reactionEmoji.length)
        d[@"reaction_emoji"] = self.reactionEmoji;
    if (self.reactionTargetPreview.length)
        d[@"reaction_target"] = self.reactionTargetPreview;
    if (self.reactionTargetKind != SPKDeletedMessageKindUnknown)
        d[@"reaction_target_kind"] = SPKDeletedMessageKindToString(self.reactionTargetKind);
    if (self.shareSubtype.length)
        d[@"share_subtype"] = self.shareSubtype;
    if (self.shareAuthor.length)
        d[@"share_author"] = self.shareAuthor;
    return d;
}

@end

@implementation SPKDeletedMessageGroup

- (NSUInteger)count {
    return self.messages.count;
}
- (NSDate *)lastDeletedAt {
    return self.latest.deletedAt ?: self.latest.capturedAt;
}
- (SPKDeletedMessage *)latest {
    return self.messages.firstObject;
}

- (NSString *)displayName {
    if (self.isGroup) {
        if (self.threadTitle.length)
            return self.threadTitle;
        return SPKL(@"MESSAGES_DELETED_MESSAGES_MODELS_GROUP_CHAT_TEXT");
    }
    if (self.senderUsername.length)
        return [@"@" stringByAppendingString:self.senderUsername];
    if (self.senderFullName.length)
        return self.senderFullName;
    return SPKL(@"MESSAGES_DELETED_MESSAGES_MODELS_UNKNOWN_USER_TEXT");
}

- (NSString *)flagKey {
    if (self.isGroup)
        return self.threadId.length ? [@"thread:" stringByAppendingString:self.threadId] : @"";
    return self.senderPk ?: @"";
}

@end
