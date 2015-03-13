﻿using OmniSharp.Common;

namespace OmniSharp.AutoComplete
{
    public class AutoCompleteRequest : Request
    {
        private string _wordToComplete;
        public string WordToComplete {
            get {
                return _wordToComplete ?? "";
            }
            set {
                _wordToComplete = value;
            }
        }
        private bool _wantDocumentationForEveryCompletionResult = false;
        private bool _wantImportableTypes = false;

        /// <summary>
        ///   Specifies whether to return the code documentation for
        ///   each and every returned autocomplete result.        
        /// </summary>
        public bool WantDocumentationForEveryCompletionResult {
            get { return _wantDocumentationForEveryCompletionResult; }
            set { _wantDocumentationForEveryCompletionResult = value; }
        }

        /// <summary>
        ///   Specifies whether to return importable types. Defaults to
        ///   false. Can be turned off to get a small speed boost.
        /// </summary>
        public bool WantImportableTypes {
            get { return _wantImportableTypes; }
            set { _wantImportableTypes = value; }
        }

    }
}
