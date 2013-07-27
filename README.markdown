# Templated Text Formatters

- Version: 1.9
- Author: Marcin Konicki (http://ahwayakchih.neoni.net)
- Build Date: 26 July 2013
- Requirements: Symphony 2.3.3 or greater.
- Text rendered on screenshots was rendered with Lobster font (http://www.impallari.com/lobster/) created by Pablo Impallari.


## Installation

1. Check if `/symphony/workspace/text-formatters` exists and is writable  by Symphony.
2. Upload the `templatedtextformatters` folder in this archive to your Symphony `extensions` folder.
3. Enable it by selecting the "Templated Text Formatters" on `System/Extensions` page, choose Enable from the with-selected menu, then click Apply.
4. Go to `Blueprints/Templated Text Formatters` and create new text formatters.


## Changelog

- **1.9** Update for Symphony 2.3.3. This may break compatibility with Symphony 2.3. Updated Markdown template.
- **1.8** Update for Symphony 2.3. This drops compatibility with Symphony 2.2. Removed Makrell formatter (Makrell project is dead). Fixed a bug in XSLT template (error when there was no utility found).
- **1.7** New template: XSLT.
- **1.6** Update for Symphony 2.2, fixed few bugs, updated Markdown template, added new template: Makrell, changed this README to Markdown syntax.
- **1.5** Update for Symphony 2.0.3. This drops compatibility with Symphony 2.0.2.
- **1.4** A lot of fixes, support translations, updated Markdown template.
- **1.3** Fixes and new template: XSS killer.
- **1.2** Initial release.


## Usage

You can create new text formatters by selecting template file and then configuring its options.
There is special "chain" formatter, that will allow you to chain text formatters, so they will be used one after another to format text. This can be very useful to extend existing formatters to add own markup and/or handle special characters.


## Developers

Developers of text-formatters can now make them "template-friendly".

1. Create 'template' subdirectory in your formatter extension directory.
2. Create file 'formatter.X.tpl' there. X is the ID of type, try to make it as unique as possible, so no other extensions will clash with it.
3. Check 'template/formatter.regex.tpl' and 'template/formatter.chain.tpl' (this one is a bit more complicated) templates to see how to create new templates. In short: look for '/* BIG CAPS STRING HERE */' parts which are "placeholders" for PHP code and/or variables. Look for ttf_tokens() function which can return placeholder names and data which should be put in those placeholders. ttf_form() function allows module to add own widgets to text formatter edit page.


## Known issues

1. After changing settings of formatter, you have to save every entry with fields that are formatted by it. Otherwise their data will stay unchanged :(. I don't know how (except for some very ugly hacks) to make textareas and other fields using text-formatters to update their content. Maybe formatted text should be cached with some known hash ID (or by text-formatter id)? That way it would be easy to refresh all content when needed (like: clear cache of every text formatted with X).
2. I'm not sure about escaping PHP code parts. I tried to make it secure, but... well... backup Your installation before testing this :).

