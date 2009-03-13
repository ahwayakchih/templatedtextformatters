<?php

	Class formatter/* CLASS NAME */ extends TextFormatter{
		private $_use_markdownextra;
		private $_use_smartypants;

		function __construct(&$parent){
			parent::__construct($parent);

			$this->_use_markdownextra = '/* USE MARKDOWNEXTRA */';
			$this->_use_smartypants = '/* USE SMARTYPANTS */';
		}
		
		function about(){
			return array(
				'name' => '/* NAME */', // required
				'author' => array(
					'name' => '/* AUTHOR NAME */',
					'website' => '/* AUTHOR WEBSITE */',
					'email' => '/* AUTHOR EMAIL */'
				),
				'version' => '1.0',
				'release-date' => '/* RELEASE DATE */',
				'description' => '/* DESCRIPTION */',
				'templatedtextformatters-version' => '/* TEMPLATEDTEXTFORMATTERS VERSION */', // required
				'templatedtextformatters-type' => '/* TEMPLATEDTEXTFORMATTERS TYPE */' // required
			);
		}
				
		function run($string){
			if (!$string || !file_exists(EXTENSIONS . '/markdown/lib/')) return $string;

		    if (!function_exists('Markdown')) {
				if ($this->_use_markdownextra == 'yes' && file_exists(EXTENSIONS . '/markdown/lib/markdown_extra.php')) @include(EXTENSIONS . '/markdown/lib/markdown_extra.php');
				else if (file_exists(EXTENSIONS . '/markdown/lib/markdown.php')) @include_once(EXTENSIONS . '/markdown/lib/markdown.php');
			}

			if (function_exists('Markdown')) {
				$string = Markdown($string);
			}

			if ($this->_use_smartypants == 'yes' && !function_exists('SmartyPants')) {
				if (file_exists(EXTENSIONS . '/markdown/lib/smartypants.php')) @include_once(EXTENSIONS . '/markdown/lib/smartypants.php');
				else $this->_use_smartypants = false;
			}

			if ($this->_use_smartypants == 'yes') {
				return SmartyPants(stripslashes($string));
			}

			return stripslashes($string);
		}

		// Hook for driver to call when generating edit form
		// Add form fields to $form
		function ttf_form(&$form, &$page) {
			$label = Widget::Label();
			$input = Widget::Input('fields[use_markdownextra]', 'yes', 'checkbox', ($this->_use_markdownextra ? array('checked' => 'checked') : NULL));
			$label->setValue(__('%1$s Use <a href="%2$s" target="_blank">MarkdownExtra</a> syntax', array($input->generate(false), 'http://michelf.com/projects/php-markdown/extra/')));
			$form->appendChild($label);

			$label = Widget::Label();
			$input = Widget::Input('fields[use_smartypants]', 'yes', 'checkbox', ($this->_use_smartypants ? array('checked' => 'checked') : NULL));
			$label->setValue(__('%1$s Use <a href="%2$s" target="_blank">SmartyPants</a> filter', array($input->generate(false), 'http://michelf.com/projects/php-smartypants/')));
			$form->appendChild($label);
		}

		// Hook called by TemplatedTextFormatters when saving formatter
		// @return array where each key is a string which will be replaced in this template, and value is what key will be replaced with.
		function ttf_tokens() {
			// Reconstruct our current patterns array and description, so they are up-to-date when form is viewed right after save, without refresh/redirect
			$this->_use_markdownextra = $_POST['fields']['use_markdownextra'];
			$this->_use_smartypants = $_POST['fields']['use_smartypants'];
			$markdown = ($this->_use_markdownextra ? 'MarkdownExtra' : 'Markdown');
			$this->_description = ($this->_use_smartypants ? __('%1$s with %2$s', array($markdown, 'SmartyPants')) : __('%1$s', array($markdown)));

			return array(
				'/*'.' DESCRIPTION */' => $this->_description,
				'/*'.' USE MARKDOWNEXTRA */' => $this->_use_markdownextra,
				'/*'.' USE SMARTYPANTS */' => $this->_use_smartypants
			);
		}
	}

?>