
Templated Text Formatters
------------------------------------

Version: 1.2
Author: Marcin Konicki (http://ahwayakchih.neoni.net)
Build Date: 10 December 2008
Requirements: Symphony Beta revision 5 or greater.


[INSTALLATION]

1. Check if /symphony/workspace/text-formatters exists and is writeable by Symphony.

2. Upload the 'templatedtextformatters' folder in this archive to your Symphony 'extensions' folder.

3. Enable it at System > Extensions.

4. Go to Blueprints > Templated Text Formatters and create new formatters.

5. Have fun with chaining formatters!


[DEVELOPERS]

Developers of text-formatters can now make them "template-friendly".

1. Create 'template' subdirectory in extension directory.

2. Create file 'formatter.X.tpl' there. X is the ID of type, try to make it as unique as possible, so no other extensions clash with it.

3. Check 'template/formatter.regex.tpl' and 'template/formatter.chain.tpl' (this one is a bit more complicated) templates
   to see how to create new templates.
   In short: look for '/* BIG CAPS STRING HERE */' parts which are "placeholders" for PHP code.
   Look for ttf_tokens() function which can return placeholder names and PHP code which should be put in those placeholders.
   ttf_form() function allows module to add own widgets to text formatter edit page.

[KNOWN ISSUES]

1. After You change settings of formatter, You have to save every entry which uses it, before data is changed :(. I don't know how (except for some very ugly hacks) to make textareas and other fields using text-formatters to update their content. Maybe formatted text should be cached with some known hash ID (or by text-formatter id)? That way it would be easy to refresh all content when needed (like: clear cache of every text formatted with X).

2. There is no recursion detection! So be careful before You start chaining chained formatters :).

3. I'm not sure about escaping PHP code parts. I tried to make it secure, but... well... backup Your installation before testing this :).

