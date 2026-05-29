# The switcher / portfolio front door at "/". Renders one card per Showcase app.
# Deliberately chromeless (no app shell) so it reads as a gallery, not a product.
class GalleryController < ApplicationController
  def index
    @apps = Showcase.all
  end
end
