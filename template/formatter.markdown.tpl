<?php

	Class formatter/* CLASS NAME */ extends TextFormatter {

		private $_use_markdownextra;
		private $_use_smartypants;
		private $_use_link_class;
		private $_use_backlink_class;

		private static $_markdown;

		public function __construct(&$parent) {
			parent::__construct($parent);

			$this->_use_markdownextra = '/* USE MARKDOWNEXTRA */';
			$this->_use_smartypants = '/* USE SMARTYPANTS */';
			$this->_use_link_class = '/* USE LINK CLASS */';
			$this->_use_backlink_class = '/* USE BACKLINK CLASS */';
		}
		
		public function about() {
			return array(
				'name' => '/* NAME */', // required
				'author' => array(
					'name' => '/* AUTHOR NAME */',
					'website' => '/* AUTHOR WEBSITE */',
					'email' => '/* AUTHOR EMAIL */'
				),
				'version' => '1.1',
				'release-date' => '/* RELEASE DATE */',
				'description' => '/* DESCRIPTION */',
				'templatedtextformatters-version' => '/* TEMPLATEDTEXTFORMATTERS VERSION */', // required
				'templatedtextformatters-type' => '/* TEMPLATEDTEXTFORMATTERS TYPE */' // required
			);
		}
				
		public function run($string) {
			if (!$string) return $string;

			if (!isset(self::$_markdown)) {
				if (!file_exists(EXTENSIONS . '/markdown/lib/markdown.php')) {
					self::$_markdown = false;
				}
				else {
					@include_once(EXTENSIONS . '/markdown/lib/markdown.php');
					if ($this->_use_markdownextra == 'yes') {
						self::$_markdown = new MarkdownExtra_Parser();
						self::$_markdown->fn_link_class = $this->_use_link_class;
						self::$_markdown->fn_backlink_class = $this->_use_backlink_class;
					}
					else self::$_markdown = new Markdown_Parser();
				}
			}

			if ($this->_use_smartypants == 'yes' && !function_exists('SmartyPants')) {
				if (file_exists(EXTENSIONS . '/markdown/lib/smartypants.php')) @include_once(EXTENSIONS . '/markdown/lib/smartypants.php');
				else $this->_use_smartypants = false;
			}

			if ($this->_use_smartypants == 'yes') {
				return SmartyPants(stripslashes(self::$_markdown !== false ? self::$_markdown->transform($string) : $string));
			}

			return stripslashes(self::$_markdown !== false ? self::$_markdown->transform($string) : $string);
		}

		// Hook for driver to call when generating edit form
		// Add form fields to $form
		public function ttf_form(&$form, &$page) {
			$div = new XMLElement('div');
			$div->setAttribute('class', 'group');

			$label = Widget::Label();
			$input = Widget::Input('fields[use_markdownextra]', 'yes', 'checkbox', ($this->_use_markdownextra == 'yes' ? array('checked' => 'checked') : NULL));
			$label->setValue(__('%1$s Use <a href="%2$s" target="_blank">MarkdownExtra</a> syntax', array($input->generate(false), 'http://michelf.com/projects/php-markdown/extra/')));
			$div->appendChild($label);

			$label = Widget::Label();
			$input = Widget::Input('fields[use_smartypants]', 'yes', 'checkbox', ($this->_use_smartypants == 'yes' ? array('checked' => 'checked') : NULL));
			$label->setValue(__('%1$s Use <a href="%2$s" target="_blank">SmartyPants</a> filter', array($input->generate(false), 'http://michelf.com/projects/php-smartypants/')));
			$div->appendChild($label);

			$form->appendChild($div);

			$div = new XMLElement('div');
			$div->setAttribute('class', 'group');

			$label = Widget::Label(__('Footnote link class'));
			$label->appendChild(new XMLElement('i', __('optional')));
			$input = Widget::Input('fields[use_link_class]', $this->_use_link_class);
			$label->appendChild($input);
			$div->appendChild($label);

			$label = Widget::Label(__('Footnote backlink class'));
			$label->appendChild(new XMLElement('i', __('optional')));
			$input = Widget::Input('fields[use_backlink_class]', $this->_use_backlink_class);
			$label->appendChild($input);
			$div->appendChild($label);

			$form->appendChild($div);
		}

		// Hook called by TemplatedTextFormatters when saving formatter
		// @return array where each key is a string which will be replaced in this template, and value is what key will be replaced with.
		public function ttf_tokens() {
			// Reconstruct our current patterns array and description, so they are up-to-date when form is viewed right after save, without refresh/redirect
			$this->_use_markdownextra = (isset($_POST['fields']['use_markdownextra']) ? $_POST['fields']['use_markdownextra'] : 'no');
			$this->_use_smartypants = (isset($_POST['fields']['use_smartypants']) ? $_POST['fields']['use_smartypants'] : 'no');
			$this->_use_link_class = $_POST['fields']['use_link_class'];
			$this->_use_backlink_class = $_POST['fields']['use_backlink_class'];
			$markdown = ($this->_use_markdownextra ? 'MarkdownExtra' : 'Markdown');
			$this->_description = ($this->_use_smartypants ? __('%1$s with %2$s', array($markdown, 'SmartyPants')) : __('%1$s', array($markdown)));

			return array(
				'/*'.' DESCRIPTION */' => $this->_description,
				'/*'.' USE MARKDOWNEXTRA */' => $this->_use_markdownextra,
				'/*'.' USE SMARTYPANTS */' => $this->_use_smartypants,
				'/*'.' USE LINK CLASS */' => $this->_use_link_class,
				'/*'.' USE BACKLINK CLASS */' => $this->_use_backlink_class
			);
		}
	}

