
# Ensure WickedPdf uses the wkhtmltopdf binary we extracted to /tmp. This is
# a pragmatic local fix; for production bake the binary into the image at
# /usr/local/bin and update the path accordingly.
exe = ENV['WKHTMLTOPDF_PATH'].presence || '/tmp/wkhtmltopdf'
# Export env for any subprocesses that may inspect it
ENV['WKHTMLTOPDF_PATH'] = exe

WickedPdf.config ||= {}
WickedPdf.config[:exe_path] = exe
WickedPdf.config[:layout] = 'pdf' if defined?(WickedPdf)
# config/initializers/wicked_pdf.rb
WickedPdf.config ||= {}
