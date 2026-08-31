#!/usr/bin/env python3
"""Generate the shared count entries used by SPKLP from reviewed noun forms."""

from __future__ import annotations

import plistlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUNDLE = ROOT / "resources" / "Sparkle.bundle"
TRANSLATIONS = ROOT / "translations"


def catalog_dir(language: str) -> Path:
    """Shipped catalogs live in the bundle; community catalogs in translations/."""
    shipped = BUNDLE / f"{language}.lproj"
    return shipped if shipped.is_dir() else TRANSLATIONS / f"{language}.lproj"

FORMS = {
    "en": {"FILE": ("%ld file", "%ld files"), "ITEM": ("%ld item", "%ld items"), "USER": ("%ld user", "%ld users"), "PARTICIPANT": ("%ld participant", "%ld participants"), "MESSAGE": ("%ld message", "%ld messages"), "SENDER": ("%ld sender", "%ld senders")},
    "de": {"FILE": ("%ld Datei", "%ld Dateien"), "ITEM": ("%ld Element", "%ld Elemente"), "USER": ("%ld Benutzer", "%ld Benutzer"), "PARTICIPANT": ("%ld Teilnehmer", "%ld Teilnehmer"), "MESSAGE": ("%ld Nachricht", "%ld Nachrichten"), "SENDER": ("%ld Absender", "%ld Absender")},
    "el": {"FILE": ("%ld αρχείο", "%ld αρχεία"), "ITEM": ("%ld στοιχείο", "%ld στοιχεία"), "USER": ("%ld χρήστης", "%ld χρήστες"), "PARTICIPANT": ("%ld συμμετέχων", "%ld συμμετέχοντες"), "MESSAGE": ("%ld μήνυμα", "%ld μηνύματα"), "SENDER": ("%ld αποστολέας", "%ld αποστολείς")},
    "es-ES": {"FILE": ("%ld archivo", "%ld archivos"), "ITEM": ("%ld elemento", "%ld elementos"), "USER": ("%ld usuario", "%ld usuarios"), "PARTICIPANT": ("%ld participante", "%ld participantes"), "MESSAGE": ("%ld mensaje", "%ld mensajes"), "SENDER": ("%ld remitente", "%ld remitentes")},
    "fr": {"FILE": ("%ld fichier", "%ld fichiers"), "ITEM": ("%ld élément", "%ld éléments"), "USER": ("%ld utilisateur", "%ld utilisateurs"), "PARTICIPANT": ("%ld participant", "%ld participants"), "MESSAGE": ("%ld message", "%ld messages"), "SENDER": ("%ld expéditeur", "%ld expéditeurs")},
    "hi": {"FILE": ("%ld फ़ाइल", "%ld फ़ाइलें"), "ITEM": ("%ld आइटम", "%ld आइटम"), "USER": ("%ld उपयोगकर्ता", "%ld उपयोगकर्ता"), "PARTICIPANT": ("%ld प्रतिभागी", "%ld प्रतिभागी"), "MESSAGE": ("%ld संदेश", "%ld संदेश"), "SENDER": ("%ld प्रेषक", "%ld प्रेषक")},
    "it": {"FILE": ("%ld file", "%ld file"), "ITEM": ("%ld elemento", "%ld elementi"), "USER": ("%ld utente", "%ld utenti"), "PARTICIPANT": ("%ld partecipante", "%ld partecipanti"), "MESSAGE": ("%ld messaggio", "%ld messaggi"), "SENDER": ("%ld mittente", "%ld mittenti")},
    "ja": {"FILE": ("%ld個のファイル", "%ld個のファイル"), "ITEM": ("%ld件", "%ld件"), "USER": ("%ld人のユーザー", "%ld人のユーザー"), "PARTICIPANT": ("%ld人の参加者", "%ld人の参加者"), "MESSAGE": ("%ld件のメッセージ", "%ld件のメッセージ"), "SENDER": ("%ld人の送信者", "%ld人の送信者")},
    "ko": {"FILE": ("파일 %ld개", "파일 %ld개"), "ITEM": ("항목 %ld개", "항목 %ld개"), "USER": ("사용자 %ld명", "사용자 %ld명"), "PARTICIPANT": ("참여자 %ld명", "참여자 %ld명"), "MESSAGE": ("메시지 %ld개", "메시지 %ld개"), "SENDER": ("보낸 사람 %ld명", "보낸 사람 %ld명")},
    "pt-BR": {"FILE": ("%ld arquivo", "%ld arquivos"), "ITEM": ("%ld item", "%ld itens"), "USER": ("%ld usuário", "%ld usuários"), "PARTICIPANT": ("%ld participante", "%ld participantes"), "MESSAGE": ("%ld mensagem", "%ld mensagens"), "SENDER": ("%ld remetente", "%ld remetentes")},
    "ro": {"FILE": ("%ld fișier", "%ld fișiere"), "ITEM": ("%ld element", "%ld elemente"), "USER": ("%ld utilizator", "%ld utilizatori"), "PARTICIPANT": ("%ld participant", "%ld participanți"), "MESSAGE": ("%ld mesaj", "%ld mesaje"), "SENDER": ("%ld expeditor", "%ld expeditori")},
    "tr": {"FILE": ("%ld dosya", "%ld dosya"), "ITEM": ("%ld öğe", "%ld öğe"), "USER": ("%ld kullanıcı", "%ld kullanıcı"), "PARTICIPANT": ("%ld katılımcı", "%ld katılımcı"), "MESSAGE": ("%ld mesaj", "%ld mesaj"), "SENDER": ("%ld gönderen", "%ld gönderen")},
    "vi": {"FILE": ("%ld tệp", "%ld tệp"), "ITEM": ("%ld mục", "%ld mục"), "USER": ("%ld người dùng", "%ld người dùng"), "PARTICIPANT": ("%ld người tham gia", "%ld người tham gia"), "MESSAGE": ("%ld tin nhắn", "%ld tin nhắn"), "SENDER": ("%ld người gửi", "%ld người gửi")},
    "zh-Hans": {"FILE": ("%ld 个文件", "%ld 个文件"), "ITEM": ("%ld 项", "%ld 项"), "USER": ("%ld 位用户", "%ld 位用户"), "PARTICIPANT": ("%ld 位参与者", "%ld 位参与者"), "MESSAGE": ("%ld 条消息", "%ld 条消息"), "SENDER": ("%ld 位发送者", "%ld 位发送者")},
}

SLAVIC = {
    "ru": {"FILE": ("%ld файл", "%ld файла", "%ld файлов"), "ITEM": ("%ld элемент", "%ld элемента", "%ld элементов"), "USER": ("%ld пользователь", "%ld пользователя", "%ld пользователей"), "PARTICIPANT": ("%ld участник", "%ld участника", "%ld участников"), "MESSAGE": ("%ld сообщение", "%ld сообщения", "%ld сообщений"), "SENDER": ("%ld отправитель", "%ld отправителя", "%ld отправителей")},
    "uk": {"FILE": ("%ld файл", "%ld файли", "%ld файлів"), "ITEM": ("%ld елемент", "%ld елементи", "%ld елементів"), "USER": ("%ld користувач", "%ld користувачі", "%ld користувачів"), "PARTICIPANT": ("%ld учасник", "%ld учасники", "%ld учасників"), "MESSAGE": ("%ld повідомлення", "%ld повідомлення", "%ld повідомлень"), "SENDER": ("%ld відправник", "%ld відправники", "%ld відправників")},
}

ARABIC = {"FILE": ("%ld ملف", "%ld ملفان", "%ld ملفات", "%ld ملفًا"), "ITEM": ("%ld عنصر", "%ld عنصران", "%ld عناصر", "%ld عنصرًا"), "USER": ("%ld مستخدم", "%ld مستخدمان", "%ld مستخدمين", "%ld مستخدمًا"), "PARTICIPANT": ("%ld مشارك", "%ld مشاركان", "%ld مشاركين", "%ld مشاركًا"), "MESSAGE": ("%ld رسالة", "%ld رسالتان", "%ld رسائل", "%ld رسالة"), "SENDER": ("%ld مرسل", "%ld مرسلان", "%ld مرسلين", "%ld مرسلًا")}

OTHER = {
    "en": ("%ld other", "%ld others"), "ar": ("%ld آخر", "%ld آخران", "%ld آخرين", "%ld آخرين"),
    "de": ("%ld weitere", "%ld weitere"), "el": ("%ld ακόμη", "%ld ακόμη"), "es-ES": ("%ld más", "%ld más"),
    "fr": ("%ld autre", "%ld autres"), "hi": ("%ld अन्य", "%ld अन्य"), "it": ("%ld altro", "%ld altri"),
    "ja": ("他%ld人", "他%ld人"), "ko": ("외 %ld명", "외 %ld명"), "pt-BR": ("%ld outro", "%ld outros"),
    "ro": ("încă %ld", "încă %ld"), "ru": ("ещё %ld", "ещё %ld"), "tr": ("%ld kişi daha", "%ld kişi daha"),
    "uk": ("ще %ld", "ще %ld"), "vi": ("%ld người khác", "%ld người khác"), "zh-Hans": ("另外 %ld 人", "另外 %ld 人"),
}


def plural_entry(forms: dict[str, str]) -> dict[str, object]:
    return {"NSStringLocalizedFormatKey": "%#@count@", "count": {"NSStringFormatSpecTypeKey": "NSStringPluralRuleType", "NSStringFormatValueTypeKey": "ld", **forms}}


def main() -> None:
    languages = set(FORMS) | set(SLAVIC) | {"ar"}
    for language in sorted(languages):
        output = {}
        concepts = ARABIC if language == "ar" else SLAVIC.get(language, FORMS.get(language))
        for concept, values in concepts.items():
            if language == "ar":
                one, two, few, many = values
                forms = {"zero": many, "one": one, "two": two, "few": few, "many": many, "other": many}
            elif language in SLAVIC:
                one, few, many = values
                forms = {"one": one, "few": few, "many": many, "other": few}
            else:
                one, other = values
                forms = {"one": one, "other": other}
            output[f"COMMON_{concept}_COUNT"] = plural_entry(forms)
        other = OTHER[language]
        if language == "ar":
            one, two, few, many = other
            other_forms = {"zero": many, "one": one, "two": two, "few": few, "many": many, "other": many}
        else:
            one, many = other
            other_forms = {"one": one, "other": many}
        output["COMMON_OTHER_COUNT"] = plural_entry(other_forms)
        path = catalog_dir(language) / "Localizable.stringsdict"
        with path.open("wb") as stream:
            plistlib.dump(output, stream, fmt=plistlib.FMT_XML, sort_keys=True)
    print(f"generated shared plural rules for {len(languages)} locales")


if __name__ == "__main__":
    main()
