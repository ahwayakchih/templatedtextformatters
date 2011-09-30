<?php
	include_once(TOOLKIT . '/class.textformattermanager.php');

	// Template class name must be constructed as: formatter___[type]/* CLASS NAME */
	// where [type] is name of type of formatter, e.g., "markdown", "chain", etc...
	// That way editor can use it at the same time as other templated formatters and 
	// formatters generated from them.
	// When saving, ___[type]/* CLASS NAME */ will be replaced by class name entered in editor.
	Class formatter___xslt/* CLASS NAME */ extends TextFormatter {

		private $_xsltfile;

		private static $_xsltproc;

		public function __construct(&$parent) {
			parent::__construct($parent);

			/* XSLT UTILITY */;
		}
		
		public function about() {
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
				
		public function run($string) {
			if (!$string) return $string;

			if (!isset(self::$_xsltproc)) {
				$_xsltproc = false;

				if (!empty($this->_xsltfile)) {
					$XSLTfilename = UTILITIES . '/'. preg_replace(array('%/+%', '%(^|/)\.\./%'), '/', $this->_xsltfile);
					if (file_exists($XSLTfilename)) {
						$xslt = new DomDocument;
						if ($xslt->load($XSLTfilename)) {
							self::$_xsltproc = new XsltProcessor;
							self::$_xsltproc->importStyleSheet($xslt);
						}
					}
				}
			}

			if (self::$_xsltproc) {
				$xml = new XMLElement('data', $string, array('class' => '/* CLASS NAME */'));

				$dom = new DOMDocument();
				$dom->strictErrorChecking = false;
				if ($dom->loadXML($xml->generate(true))) {
					$result = self::$_xsltproc->transformToXML($dom);
					if ($result !== FALSE) return $result;
				}
			}

			return $string;
		}

		// Hook for driver to call when generating edit form
		// Add form fields to $form
		public function ttf_form(&$form, &$page) {
			$div = new XMLElement('div');
			$label = Widget::Label(__('XSLT Utility'));

			$utilities = General::listStructure(UTILITIES, array('xsl'), false, 'asc', UTILITIES);
			$utilities = $utilities['filelist'];

			$xsltfile = ($this->_xsltfile ? $this->_xsltfile : $_POST['fields']['xsltfile']);
			$options = array();

			foreach ($utilities as $utility) {
				$options[] = array($utility, ($xsltfile == $utility), $utility);
			}

			$label->appendChild(Widget::Select('fields[xsltfile]', $options));
			
			$help = new XMLElement('p');
			$help->setAttribute('class', 'help');
			
			$help->setValue(__('Select XSLT which will be used to transform XML with a single /data node containing text to format.'));
			
			$div->appendChild($label);
			$div->appendChild($help);
			$form->appendChild($div);
		}

		// Hook called by TemplatedTextFormatters when generating formatter
		// Update internal data from $_POST only when $update == true.
		// @return array where each key is a string which will be replaced in this template, and value is what key will be replaced with.
		public function ttf_tokens($update = true) {
			if ($update) {
				$this->_xsltfile = (isset($_POST['fields']['xsltfile']) ? trim($_POST['fields']['xsltfile']) : '');
			}

			return array(
				'/*'.' XSLT UTILITY */' => '$this->_xsltfile = '.var_export($this->_xsltfile, true),
			);
		}
	}

