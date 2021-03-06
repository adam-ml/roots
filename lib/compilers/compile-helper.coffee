path = require 'path'
fs = require 'fs'
debug = require '../debug'

# this class is absurd. its purpose is to resolve and
# hold on to all the file paths and file contents necessary to
# compile the file. this looks messy, but it's necessary and is
# what keeps the actual compilers so clean

module.exports = class CompileHelper

  constructor: (@file) ->

    options = global.options
    @extension = path.extname(@file).slice(1)
    @current_directory = path.normalize process.cwd()

    html_file = options.file_types.html.indexOf(@extension) > -1
    css_file = options.file_types.css.indexOf(@extension) > -1
    js_file = options.file_types.js.indexOf(@extension) > -1

    if html_file
      @target_extension = 'html'
      base_folder = options.folder_config.views

      # deal with layouts
      @layout = options.layouts.default
      for file, layout_path of options.layouts
        @layout = layout_path if @file == file

      @layout_path = path.join @current_directory, base_folder, @layout
      @layout_contents = fs.readFileSync @layout_path, 'utf8'

    else if css_file
      @target_extension = 'css'
      base_folder = options.folder_config.assets

    # if we're working with file that will compile to js
    else if js_file
      @target_extension = 'js'
      base_folder = options.folder_config.assets

    # something really whack happened
    else
      throw "unsupported file extension for file: #{@file}"

    @file_path = path.join @current_directory, base_folder, @file
    @file_contents = fs.readFileSync @file_path, 'utf8'
    @export_path = path.join @current_directory, 'public', path.dirname(@file), "#{path.basename @file, path.extname(@file)}.#{@target_extension}"
  
  # extra locals (like yield) can be added here
  locals: (extra) ->
    for key, value of extra
      options.locals[key] = value
    return options.locals

  write: (write_content) ->
    write_content = @compress(write_content) if options.compress
    fs.writeFileSync @export_path, write_content
    debug.log "compiled #{path.basename(@file)}"

  compress: (write_content) ->
    require('../utils/compressor')(write_content, @target_extension)