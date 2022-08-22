Fujiten is a Japanese dictionary application made with the flutter framework.

Definition and kanji comes from the EDICT dictionary, compiled as a database from the edict_database project.


# Setup

In order to fujiten to work, the Expression Database and the Kanji Database are needed.

The databases can be downloaded and installed from fujiten via the "settings/databases menu or by downloading the database manually from https://github.com/odrevet/edict_database

# Top menu

## Bars

Access the settings menu.

The settings menu allow you to download the dictionaries, set brightness and read legal information.

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

In case your device is not equipped with a Japanese input keyboard, fujiten can convert Latin character (romaji) to hiragana or katakana.

Lowercase romaji will be converted to hiragana, uppercase romaji will be converted to katakana.


# Kotoba / Kanji search

When Kotoba is selected, fujiten will search for expression.

When Kanji is selected, fujiten will search for kanji.

## Clear

Clear the input field.

## Search

Run the search.

# Tips

* Search are performed with regular expression, quantifiers "{}" and meta-characters like "." and others can be use

* Use search by radical < > when searching for an expression which you do not know a kanji but recognize some of it's radical example: ＜化＞

* When no results, add ".*" at the beginning or the end of your search