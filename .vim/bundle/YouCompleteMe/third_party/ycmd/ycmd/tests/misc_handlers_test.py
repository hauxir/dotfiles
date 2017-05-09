# Copyright (C) 2013 Google Inc.
#               2015 ycmd contributors
#
# This file is part of ycmd.
#
# ycmd is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ycmd is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with ycmd.  If not, see <http://www.gnu.org/licenses/>.

from __future__ import unicode_literals
from __future__ import print_function
from __future__ import division
from __future__ import absolute_import
from future import standard_library
standard_library.install_aliases()
from builtins import *  # noqa

from hamcrest import assert_that, contains, empty, equal_to, has_entries
import requests

from ycmd.tests import PathToTestFile, SharedYcmd
from ycmd.tests.test_utils import BuildRequest, DummyCompleter, PatchCompleter


@SharedYcmd
def MiscHandlers_SemanticCompletionAvailable_test( app ):
  with PatchCompleter( DummyCompleter, filetype = 'dummy_filetype' ):
    request_data = BuildRequest( filetype = 'dummy_filetype' )
    assert_that( app.post_json( '/semantic_completion_available',
                                request_data ).json,
                 equal_to( True ) )


@SharedYcmd
def MiscHandlers_EventNotification_AlwaysJsonResponse_test( app ):
  event_data = BuildRequest( contents = 'foo foogoo ba',
                             event_name = 'FileReadyToParse' )

  assert_that( app.post_json( '/event_notification', event_data ).json,
               empty() )


@SharedYcmd
def MiscHandlers_EventNotification_ReturnJsonOnBigFileError_test( app ):
  # We generate a content greater than Bottle.MEMFILE_MAX, which is set to 10MB.
  contents = "foo " * 5000000
  event_data = BuildRequest( contents = contents,
                             event_name = 'FileReadyToParse' )

  response = app.post_json( '/event_notification',
                            event_data,
                            expect_errors = True )
  assert_that( response.status_code,
               equal_to( requests.codes.request_entity_too_large ) )
  assert_that( response.json,
               has_entries( { 'traceback': None,
                              'message': 'None',
                              'exception': None } ) )


@SharedYcmd
def MiscHandlers_FilterAndSortCandidates_Basic_test( app ):
  candidate1 = { 'prop1': 'aoo', 'prop2': 'bar' }
  candidate2 = { 'prop1': 'bfo', 'prop2': 'zoo' }
  candidate3 = { 'prop1': 'cfo', 'prop2': 'moo' }

  data = {
    'candidates': [ candidate3, candidate1, candidate2 ],
    'sort_property': 'prop1',
    'query': 'fo'
  }

  response_data = app.post_json( '/filter_and_sort_candidates', data ).json

  assert_that( response_data, contains( candidate2, candidate3 ) )


@SharedYcmd
def MiscHandlers_LoadExtraConfFile_AlwaysJsonResponse_test( app ):
  filepath = PathToTestFile( '.ycm_extra_conf.py' )
  extra_conf_data = BuildRequest( filepath = filepath )

  assert_that( app.post_json( '/load_extra_conf_file', extra_conf_data ).json,
               equal_to( True ) )


@SharedYcmd
def MiscHandlers_IgnoreExtraConfFile_AlwaysJsonResponse_test( app ):
  filepath = PathToTestFile( '.ycm_extra_conf.py' )
  extra_conf_data = BuildRequest( filepath = filepath )

  assert_that( app.post_json( '/ignore_extra_conf_file', extra_conf_data ).json,
               equal_to( True ) )
