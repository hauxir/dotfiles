#!/usr/bin/env python
#
# Copyright (C) 2011, 2012  Google Inc.
#
# This file is part of YouCompleteMe.
#
# YouCompleteMe is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# YouCompleteMe is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with YouCompleteMe.  If not, see <http://www.gnu.org/licenses/>.

from collections import defaultdict
import ycm_core
from ycmd import responses
from ycmd import extra_conf_store
from ycmd.utils import ToUtf8IfNeeded
from ycmd.completers.completer import Completer
from ycmd.completers.cpp.flags import Flags, PrepareFlagsForClang
from ycmd.completers.cpp.ephemeral_values_set import EphemeralValuesSet

CLANG_FILETYPES = set( [ 'c', 'cpp', 'objc', 'objcpp' ] )
MIN_LINES_IN_FILE_TO_PARSE = 5
PARSING_FILE_MESSAGE = 'Still parsing file, no completions yet.'
NO_COMPILE_FLAGS_MESSAGE = 'Still no compile flags, no completions yet.'
INVALID_FILE_MESSAGE = 'File is invalid.'
NO_COMPLETIONS_MESSAGE = 'No completions found; errors in the file?'
FILE_TOO_SHORT_MESSAGE = (
  'File is less than {0} lines long; not compiling.'.format(
    MIN_LINES_IN_FILE_TO_PARSE ) )
NO_DIAGNOSTIC_MESSAGE = 'No diagnostic for current line!'
PRAGMA_DIAG_TEXT_TO_IGNORE = '#pragma once in main file'
TOO_MANY_ERRORS_DIAG_TEXT_TO_IGNORE = 'too many errors emitted, stopping now'


class ClangCompleter( Completer ):
  def __init__( self, user_options ):
    super( ClangCompleter, self ).__init__( user_options )
    self._max_diagnostics_to_display = user_options[
      'max_diagnostics_to_display' ]
    self._completer = ycm_core.ClangCompleter()
    self._flags = Flags()
    self._diagnostic_store = None
    self._files_being_compiled = EphemeralValuesSet()


  def SupportedFiletypes( self ):
    return CLANG_FILETYPES


  def GetUnsavedFilesVector( self, request_data ):
    files = ycm_core.UnsavedFileVector()
    for filename, file_data in request_data[ 'file_data' ].iteritems():
      if not ClangAvailableForFiletypes( file_data[ 'filetypes' ] ):
        continue
      contents = file_data[ 'contents' ]
      if not contents or not filename:
        continue

      unsaved_file = ycm_core.UnsavedFile()
      utf8_contents = ToUtf8IfNeeded( contents )
      unsaved_file.contents_ = utf8_contents
      unsaved_file.length_ = len( utf8_contents )
      unsaved_file.filename_ = ToUtf8IfNeeded( filename )

      files.append( unsaved_file )
    return files


  def ComputeCandidatesInner( self, request_data ):
    filename = request_data[ 'filepath' ]
    if not filename:
      return

    if self._completer.UpdatingTranslationUnit( ToUtf8IfNeeded( filename ) ):
      raise RuntimeError( PARSING_FILE_MESSAGE )

    flags = self._FlagsForRequest( request_data )
    if not flags:
      raise RuntimeError( NO_COMPILE_FLAGS_MESSAGE )

    files = self.GetUnsavedFilesVector( request_data )
    line = request_data[ 'line_num' ]
    column = request_data[ 'start_column' ]
    with self._files_being_compiled.GetExclusive( filename ):
      results = self._completer.CandidatesForLocationInFile(
          ToUtf8IfNeeded( filename ),
          line,
          column,
          files,
          flags )

    if not results:
      raise RuntimeError( NO_COMPLETIONS_MESSAGE )

    return [ ConvertCompletionData( x ) for x in results ]


  def DefinedSubcommands( self ):
    return [ 'GoToDefinition',
             'GoToDeclaration',
             'GoTo',
             'GoToImprecise',
             'ClearCompilationFlagCache',
             'GetType',
             'GetParent']


  def OnUserCommand( self, arguments, request_data ):
    if not arguments:
      raise ValueError( self.UserCommandsHelpMessage() )

    # command_map maps: command -> { method, args }
    #
    # where:
    #  "command" is the completer command entered by the user
    #            (e.g. GoToDefinition)
    #  "method"  is a method to call for that command 
    #            (e.g. self._GoToDefinition)
    #  "args"    is a dictionary of
    #               "method_argument" : "value" ...
    #            which defines the kwargs (via the ** double splat) 
    #            when calling "method" 
    command_map = {
        'GoToDefinition' : { 
            'method' : self._GoToDefinition,
            'args'   : { 'request_data' : request_data } 
         },
        'GoToDeclaration' : {
            'method' : self._GoToDeclaration,
            'args'   : { 'request_data' : request_data } 
        },
        'GoTo' : {
            'method' : self._GoTo,
            'args'   : { 'request_data' : request_data } 
        },
        'GoToImprecise' : {
            'method' : self._GoToImprecise,
            'args'   : { 'request_data' : request_data } 
        },
        'ClearCompilationFlagCache' : {
            'method' : self._ClearCompilationFlagCache,
            'args'   : { }
        },
        'GetType' : {
            'method' : self._GetSemanticInfo,
            'args'   : { 'request_data' : request_data,  
                         'func'         : 'GetTypeAtLocation' }
        },
        'GetParent' : {
            'method' : self._GetSemanticInfo,
            'args'   : { 'request_data' : request_data,  
                         'func'         : 'GetEnclosingFunctionAtLocation' }
        },
    }

    try:
        command_def = command_map[arguments[0]]
        return command_def['method']( **(command_def['args']) )
    except KeyError:
        raise ValueError( self.UserCommandsHelpMessage() )

  def _LocationForGoTo( self, goto_function, request_data, reparse = True ):
    filename = request_data[ 'filepath' ]
    if not filename:
      raise ValueError( INVALID_FILE_MESSAGE )

    flags = self._FlagsForRequest( request_data )
    if not flags:
      raise ValueError( NO_COMPILE_FLAGS_MESSAGE )

    files = self.GetUnsavedFilesVector( request_data )
    line = request_data[ 'line_num' ]
    column = request_data[ 'column_num' ]
    return getattr( self._completer, goto_function )(
        ToUtf8IfNeeded( filename ),
        line,
        column,
        files,
        flags,
        reparse )


  def _GoToDefinition( self, request_data ):
    location = self._LocationForGoTo( 'GetDefinitionLocation', request_data )
    if not location or not location.IsValid():
      raise RuntimeError( 'Can\'t jump to definition.' )
    return _ResponseForLocation( location )


  def _GoToDeclaration( self, request_data ):
    location = self._LocationForGoTo( 'GetDeclarationLocation', request_data )
    if not location or not location.IsValid():
      raise RuntimeError( 'Can\'t jump to declaration.' )
    return _ResponseForLocation( location )


  def _GoTo( self, request_data ):
    location = self._LocationForGoTo( 'GetDefinitionLocation', request_data )
    if not location or not location.IsValid():
      location = self._LocationForGoTo( 'GetDeclarationLocation', request_data )
    if not location or not location.IsValid():
      raise RuntimeError( 'Can\'t jump to definition or declaration.' )
    return _ResponseForLocation( location )


  def _GoToImprecise( self, request_data ):
    location = self._LocationForGoTo( 'GetDefinitionLocation',
                                      request_data,
                                      reparse = False )
    if not location or not location.IsValid():
      location = self._LocationForGoTo( 'GetDeclarationLocation',
                                        request_data,
                                        reparse = False )
    if not location or not location.IsValid():
      raise RuntimeError( 'Can\'t jump to definition or declaration.' )
    return _ResponseForLocation( location )

  def _GetSemanticInfo( self, request_data, func, reparse = True ):
    filename = request_data[ 'filepath' ]
    if not filename:
      raise ValueError( INVALID_FILE_MESSAGE )

    flags = self._FlagsForRequest( request_data )
    if not flags:
      raise ValueError( NO_COMPILE_FLAGS_MESSAGE )

    files = self.GetUnsavedFilesVector( request_data )
    line = request_data[ 'line_num' ]
    column = request_data[ 'column_num' ]

    message = getattr( self._completer, func )(
        ToUtf8IfNeeded( filename ),
        line,
        column,
        files,
        flags,
        reparse)

    if not message:
      message = "No semantic information available"

    return responses.BuildDisplayMessageResponse( message )

  def _ClearCompilationFlagCache( self ):
    self._flags.Clear()

  def OnFileReadyToParse( self, request_data ):
    filename = request_data[ 'filepath' ]
    contents = request_data[ 'file_data' ][ filename ][ 'contents' ]
    if contents.count( '\n' ) < MIN_LINES_IN_FILE_TO_PARSE:
      raise ValueError( FILE_TOO_SHORT_MESSAGE )

    if not filename:
      raise ValueError( INVALID_FILE_MESSAGE )

    flags = self._FlagsForRequest( request_data )
    if not flags:
      raise ValueError( NO_COMPILE_FLAGS_MESSAGE )

    with self._files_being_compiled.GetExclusive( filename ):
      diagnostics = self._completer.UpdateTranslationUnit(
        ToUtf8IfNeeded( filename ),
        self.GetUnsavedFilesVector( request_data ),
        flags )

    diagnostics = _FilterDiagnostics( diagnostics )
    self._diagnostic_store = DiagnosticsToDiagStructure( diagnostics )
    return [ responses.BuildDiagnosticData( x ) for x in
             diagnostics[ : self._max_diagnostics_to_display ] ]


  def OnBufferUnload( self, request_data ):
    self._completer.DeleteCachesForFile(
        ToUtf8IfNeeded( request_data[ 'unloaded_buffer' ] ) )


  def GetDetailedDiagnostic( self, request_data ):
    current_line = request_data[ 'line_num' ]
    current_column = request_data[ 'column_num' ]
    current_file = request_data[ 'filepath' ]

    if not self._diagnostic_store:
      raise ValueError( NO_DIAGNOSTIC_MESSAGE )

    diagnostics = self._diagnostic_store[ current_file ][ current_line ]
    if not diagnostics:
      raise ValueError( NO_DIAGNOSTIC_MESSAGE )

    closest_diagnostic = None
    distance_to_closest_diagnostic = 999

    for diagnostic in diagnostics:
      distance = abs( current_column - diagnostic.location_.column_number_ )
      if distance < distance_to_closest_diagnostic:
        distance_to_closest_diagnostic = distance
        closest_diagnostic = diagnostic

    return responses.BuildDisplayMessageResponse(
      closest_diagnostic.long_formatted_text_ )


  def DebugInfo( self, request_data ):
    filename = request_data[ 'filepath' ]
    if not filename:
      return ''
    flags = self._FlagsForRequest( request_data ) or []
    source = extra_conf_store.ModuleFileForSourceFile( filename )
    return 'Flags for {0} loaded from {1}:\n{2}'.format( filename,
                                                         source,
                                                         list( flags ) )


  def _FlagsForRequest( self, request_data ):
    filename = ToUtf8IfNeeded( request_data[ 'filepath' ] )
    if 'compilation_flags' in request_data:
      return PrepareFlagsForClang( request_data[ 'compilation_flags' ],
                                   filename )
    client_data = request_data.get( 'extra_conf_data', None )
    return self._flags.FlagsForFile( filename, client_data = client_data )


def ConvertCompletionData( completion_data ):
  return responses.BuildCompletionData(
    insertion_text = completion_data.TextToInsertInBuffer(),
    menu_text = completion_data.MainCompletionText(),
    extra_menu_info = completion_data.ExtraMenuInfo(),
    kind = completion_data.kind_.name,
    detailed_info = completion_data.DetailedInfoForPreviewWindow(),
    extra_data = { 'doc_string': completion_data.DocString() } if completion_data.DocString() else None )


def DiagnosticsToDiagStructure( diagnostics ):
  structure = defaultdict( lambda : defaultdict( list ) )
  for diagnostic in diagnostics:
    structure[ diagnostic.location_.filename_ ][
      diagnostic.location_.line_number_ ].append( diagnostic )
  return structure


def ClangAvailableForFiletypes( filetypes ):
  return any( [ filetype in CLANG_FILETYPES for filetype in filetypes ] )


def InCFamilyFile( filetypes ):
  return ClangAvailableForFiletypes( filetypes )


def _FilterDiagnostics( diagnostics ):
  # Clang has an annoying warning that shows up when we try to compile header
  # files if the header has "#pragma once" inside it. The error is not
  # legitimate because it shows up because libclang thinks we are compiling a
  # source file instead of a header file.
  #
  # See our issue #216 and upstream bug:
  #   http://llvm.org/bugs/show_bug.cgi?id=16686
  #
  # The second thing we want to filter out are those incredibly annoying "too
  # many errors emitted" diagnostics that are utterly useless.
  return [ x for x in diagnostics if
           x.text_ != PRAGMA_DIAG_TEXT_TO_IGNORE and
           x.text_ != TOO_MANY_ERRORS_DIAG_TEXT_TO_IGNORE ]


def _ResponseForLocation( location ):
  return responses.BuildGoToResponse( location.filename_,
                                      location.line_number_,
                                      location.column_number_ )


