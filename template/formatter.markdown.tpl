<?php
	include_once(TOOLKIT . '/class.textformattermanager.php');

	// Template class name must be constructed as: formatter___[type]/* CLASS NAME */
	// where [type] is name of type of formatter, e.g., "markdown", "chain", etc...
	// That way editor can use it at the same time as other templated formatters and 
	// formatters generated from them.
	// When saving, ___[type]/* CLASS NAME */ will be replaced by class name entered in editor.
	Class formatter___markdown/* CLASS NAME */ extends TextFormatter {

		private $_use_markdownextra;
		private $_use_smartypants;
		private $_use_link_class;
		private $_use_backlink_class;

		private static $_markdown;
		private static $_purifier;

		private static $_markdownTransform = false;

		public function __construct() {
			$this->_use_markdownextra = 'no';
			$this->_use_smartypants = 'no';
			$this->_use_htmlpurifier = 'yes';
			$this->_use_link_class = '';
			$this->_use_backlink_class = '';
		}
		
		public function about() {
			return array(
				'name' => 'MD1', // required
				'author' => array(
					'name' => 'Marcin Konicki',
					'website' => 'http://s24.neoni.net',
					'email' => 'ahwayakchih@gmail.com'
				),
				'version' => '1.1',
				'release-date' => '2015-05-19T15:09:48+00:00',
				'description' => 'MarkdownExtra with SmartyPants',
				'templatedtextformatters-version' => '1.11', // required
				'templatedtextformatters-type' => 'markdown' // required
			);
		}

		// Support Markdown: https://github.com/symphonycms/markdown
		private function initializeMarkdownDefault() {
			$markdown_path = glob(EXTENSIONS . '/markdown/lib/php-markdown-extra-*/markdown.php');

			if (!$markdown_path || count($markdown_path) < 1) {
				self::$_markdown = false;
				return self::$_markdown;
			}

			@include_once($markdown_path[0]);
			if ($this->_use_markdownextra == 'yes') {
				self::$_markdown = new MarkdownExtra_Parser();
				self::$_markdown->fn_link_class = $this->_use_link_class;
				self::$_markdown->fn_backlink_class = $this->_use_backlink_class;
			}
			else {
				self::$_markdown = new Markdown_Parser();
			}

			self::$_markdownTransform = 'transform';

			return self::$_markdown;
		}

		// Support MarkdownTypography: https://github.com/hananils/markdown_typography
		private function initializeMarkdownTypography() {
			self::$_markdown = false;

			$markdown_path = glob(EXTENSIONS . '/markdown_typography/lib/parsedown/Parsedown.php');

			if (!$markdown_path || count($markdown_path) < 1) {
				self::$_markdown = false;
				return self::$_markdown;
			}
			
			@include_once($markdown_path[0]);
			@include_once(EXTENSIONS . '/markdown_typography/lib/parsedown-extra/ParsedownExtra.php');

			if ($this->_use_markdownextra == 'yes') {
				self::$_markdown = new ParsedownExtra();
				self::$_markdown->setBreaksEnabled(true);
			}
			else {
				self::$_markdown = new Parsedown();
				self::$_markdown->setBreaksEnabled(true);
			}

			self::$_markdownTransform = 'text';

			return self::$_markdown;
		}

		private function initializeMarkdown() {
			if (isset(self::$_markdown)) {
				return self::$_markdown;
			}

			if (file_exists(EXTENSIONS . '/markdown')) {
				return self::initializeMarkdownDefault();
			}
			else if (file_exists(EXTENSIONS . '/markdown_typography')) {
				return self::initializeMarkdownTypography();
			}
			else {
				self::$_markdown = false;
			}

			return self::$_markdown;
		}

		private function initializeSmartyPants() {
			if (function_exists('SmartyPants')) {
				return true;
			}

			$search = '';
			if (file_exists(EXTENSIONS . '/markdown')) {
				$search = EXTENSIONS . '/markdown/lib/php-smartypants-*/smartypants.php';
			}
			else if (file_exists(EXTENSIONS . '/markdown_typography')) {
				$search = EXTENSIONS . '/markdown_typography/lib/smartypants/smartypants.php';
			}
			else {
				return false;
			}

			$smartypants_path = glob($search);
			if (!$smartypants_path || count($smartypants_path) < 1) {
				return false;
			}
			else {
				@include_once($smartypants_path[0]);
			}

			return function_exists('SmartyPants');
		}

		private function initializeHTMLPurifier() {
			if (isset(self::$_purifier)) {
				return self::$_purifier;
			}

			self::$_purifier = false;

			if (!class_exists('HTMLPurifier')) {
				$htmlpurifier_path = glob(EXTENSIONS . '/markdown/lib/htmlpurifier-*-standalone/HTMLPurifier.standalone.php');
				if ($htmlpurifier_path && count($htmlpurifier_path) > 0) {
					@include_once($htmlpurifier_path[0]);
				}
			}

			if (class_exists('HTMLPurifier')) {
				self::$_purifier = new HTMLPurifier(array(
					'Cache.SerializerPath' => CACHE
				));
			}

			return self::$_purifier;
		}
				
		public function run($string) {
			if (!$string) return $string;

			if (!isset(self::$_markdown)) {
				$this->initializeMarkdown();
			}

			if ($this->_use_smartypants == 'yes' && !$this->initializeSmartyPants()) {
				$this->_use_smartypants = false;
			}

			if ($this->_use_htmlpurifier == 'yes' && !$this->initializeHTMLPurifier()) {
				$this->_use_htmlpurifier = false;
			}

			$result = stripslashes(self::$_markdownTransform !== false ? self::$_markdown->{self::$_markdownTransform}($string) : $string);

			if ($this->_use_smartypants == 'yes') {
				$result = SmartyPants($result, 1);
			}

			if ($this->_use_htmlpurifier == 'yes' && self::$_purifier !== false) {
				$result = self::$_purifier->purify($result);
			}

			return $result;
		}

		// Hook for driver to call when generating edit form
		// Add form fields to $form
		public function ttf_form(&$form, &$page) {
			$this->initializeMarkdown();
			if (!self::$_markdown) {
				$form->appendChild(new XMLElement('p', __('No markdown libraries found. Please install either <a href="https://github.com/symphonycms/markdown">Markdown</a> or <a href="https://github.com/hananils/markdown_typography">Markdown Typography</a> extenstion first.')));
				return;
			}

			$this->initializeHTMLPurifier();

			// This assumes that HTMLPurifier is available only when PHPMarkdownExtra is available.
			// TODO: change this if/when we support other source of HTMLPurifier.
			if (self::$_purifier) {
				$group = new XMLElement('div');
				$group->setAttribute('class', 'two columns');

				$div = new XMLElement('div', NULL, array('class' => 'column'));
				$label = Widget::Label(__('Footnote link class'));
				$label->appendChild(new XMLElement('i', __('optional')));
				$input = Widget::Input('fields[use_link_class]', $this->_use_link_class);
				$label->appendChild($input);
				$div->appendChild($label);
				$group->appendChild($div);

				$div = new XMLElement('div', NULL, array('class' => 'column'));
				$label = Widget::Label(__('Footnote backlink class'));
				$label->appendChild(new XMLElement('i', __('optional')));
				$input = Widget::Input('fields[use_backlink_class]', $this->_use_backlink_class);
				$label->appendChild($input);
				$div->appendChild($label);
				$group->appendChild($div);

				$form->appendChild($group);
			}

			$group = new XMLElement('div');
			$group->setAttribute('class', (self::$_purifier ? 'three' : 'two') . ' columns');

			$div = new XMLElement('div', NULL, array('class' => 'column'));
			$label = Widget::Label();
			$input = Widget::Input('fields[use_markdownextra]', 'yes', 'checkbox', ($this->_use_markdownextra == 'yes' ? array('checked' => 'checked') : NULL));
			$label->setValue(__('%1$s Use <a href="%2$s" target="_blank">MarkdownExtra</a> syntax', array($input->generate(false), 'http://michelf.com/projects/php-markdown/extra/')));
			$div->appendChild($label);
			$group->appendChild($div);

			$div = new XMLElement('div', NULL, array('class' => 'column'));
			$label = Widget::Label();
			$input = Widget::Input('fields[use_smartypants]', 'yes', 'checkbox', ($this->_use_smartypants == 'yes' ? array('checked' => 'checked') : NULL));
			$label->setValue(__('%1$s Use <a href="%2$s" target="_blank">SmartyPants</a> filter', array($input->generate(false), 'http://michelf.com/projects/php-smartypants/')));
			$div->appendChild($label);
			$group->appendChild($div);

			if (self::$_purifier) {
				$div = new XMLElement('div', NULL, array('class' => 'column'));
				$label = Widget::Label();
				$input = Widget::Input('fields[use_htmlpurifier]', 'yes', 'checkbox', ($this->_use_htmlpurifier == 'yes' ? array('checked' => 'checked') : NULL));
				$label->setValue(__('%1$s Use <a href="%2$s" target="_blank">HTML Purifier</a> filter', array($input->generate(false), 'http://htmlpurifier.org/')));
				$div->appendChild($label);
				$group->appendChild($div);
			}

			$form->appendChild($group);
		}

		// Hook called by TemplatedTextFormatters when generating formatter
		// Update internal data from $_POST only when $update == true.
		// @return array where each key is a string which will be replaced in this template, and value is what key will be replaced with.
		public function ttf_tokens($update = true) {
			if ($update) {
				// Reconstruct our current patterns array and description, so they are up-to-date when form is viewed right after save, without refresh/redirect
				$this->_use_markdownextra = (isset($_POST['fields']['use_markdownextra']) ? $_POST['fields']['use_markdownextra'] : 'no');
				$this->_use_smartypants = (isset($_POST['fields']['use_smartypants']) ? $_POST['fields']['use_smartypants'] : 'no');
				$this->_use_htmlpurifier = (isset($_POST['fields']['use_htmlpurifier']) ? $_POST['fields']['use_htmlpurifier'] : 'no');
				$this->_use_link_class = $_POST['fields']['use_link_class'];
				$this->_use_backlink_class = $_POST['fields']['use_backlink_class'];
			}

			$markdown = ($this->_use_markdownextra ? 'MarkdownExtra' : 'Markdown');
			$description = ($this->_use_smartypants ? __('%1$s with %2$s', array($markdown, 'SmartyPants')) : __('%1$s', array($markdown)));

			return array(
				'/*'.' DESCRIPTION */' => $description,
				'/*'.' USE MARKDOWNEXTRA */' => $this->_use_markdownextra,
				'/*'.' USE SMARTYPANTS */' => $this->_use_smartypants,
				'/*'.' USE HTMLPURIFIER */' => $this->_use_htmlpurifier,
				'/*'.' USE LINK CLASS */' => $this->_use_link_class,
				'/*'.' USE BACKLINK CLASS */' => $this->_use_backlink_class
			);
		}
	}

