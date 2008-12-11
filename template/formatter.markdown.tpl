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
			if (!$string) return $string;

		    if(!function_exists('Markdown')) {
				if ($this->_use_markdownextra) include_once(EXTENSIONS . '/markdown/lib/markdown_extra.php');
				else include_once(EXTENSIONS . '/markdown/lib/markdown.php');
			}

			if ($this->_use_smartypants) {
				include_once(EXTENSIONS . '/markdown/lib/smartypants.php');
				return SmartyPants(stripslashes(Markdown($string)));
			}
			else return stripslashes(Markdown($string));
		}

		// Hook for driver to call when generating edit form
		// Add form fields to $form
		function ttf_form(&$form, &$page) {
			$label = Widget::Label();
			$input = Widget::Input('fields[use_markdownextra]', 'yes', 'checkbox', ($this->_use_markdownextra ? array('checked' => 'checked') : NULL));
			$label->setValue($input->generate(false) . ' Use <a href="http://michelf.com/projects/php-markdown/extra/" target="_blank">MarkdownExtra</a> syntax');
			$form->appendChild($label);

			$label = Widget::Label();
			$input = Widget::Input('fields[use_smartypants]', 'yes', 'checkbox', ($this->_use_smartypants ? array('checked' => 'checked') : NULL));
			$label->setValue($input->generate(false) . ' Use <a href="http://michelf.com/projects/php-smartypants/" target="_blank">SmartyPants</a> filter');
			$form->appendChild($label);
		}

		// Hook called by TemplatedTextFormatters when saving formatter
		// @return array where each key is a string which will be replaced in this template, and value is what key will be replaced with.
		function ttf_tokens() {
			// Reconstruct our current patterns array and description, so they are up-to-date when form is viewed right after save, without refresh/redirect
			$this->_use_markdownextra = $_POST['fields']['use_markdownextra'];
			$this->_use_smartypants = $_POST['fields']['use_smartypants'];
			$this->_description = 'Markdown'.($this->_use_markdownextra ? 'Extra' : '').($this->_use_smartypants ? ' with SmartyPants' : '');

			return array(
				'/*'.' DESCRIPTION */' => $this->_description,
				'/*'.' USE MARKDOWNEXTRA */' => $this->_use_markdownextra,
				'/*'.' USE SMARTYPANTS */' => $this->_use_smartypants
			);
		}
	}

?>