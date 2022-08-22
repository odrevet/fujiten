Fujiten is a japanese dictionary application made with the flutter framework.

Definition and kanji comes from the EDICT dictionary, compiled as a database from the edict_database project.


# Setup

In order to fukiten to work, the Expression Datase and the Kanji Database are needed.

The databases can be downloaded and installed from fujiten via the "settings/databases menu or by downloading the database manually from https://github.com/odrevet/edict_database

# Top menu

## Bars

Access the settings menu.

The settings menu allow you to download the dictionaries, set brightness and read legal informations.

## Insert

### Radicals <>

Will match kanji composed with the selected radicals

### Kanji character Ⓚ

Will match any kanji

### Kana character ㋐

Will match a hiragana/katakana character

### Joker .*

Any match

## Convert

In case your device is not equiped with a japanese input keyboard, fujiten can convert latin character (romaji) to hiragana or katakana.

Lowercase romaji will be converted to hiragana, upercase romaji will be converted to katakana.


# Kotoba / Kanji search

When Kotoba is selected, fujiten will search for expression.

When Kanji is selected, fujiten will search for kanji.

## Clear

Clear the input field.

## Search

Run the search.

# Tips

* Search are performed with regular expression, quantifiers "{}" and metacharacters like "." and others can be use

* Use search by radical < > when searching for an expression which you do not know a kanji but reconize some of it's radical example: ＜化＞

* When no results, add ".*" at the beginning or the end of your search