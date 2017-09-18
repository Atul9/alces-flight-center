class ClustersController < ApplicationController
  def index
    @site = find_site
    @clusters = @site.clusters.all
  end

  def show
    @site = find_site
    @cluster = Cluster.find(params[:id])
  end

  def new
    @site = find_site
    @cluster = @site.clusters.build
  end

  def create
    @site = find_site
    @cluster = @site.clusters.new(cluster_params)
    if @cluster.save
      redirect_to [@site, @cluster]
    else
      render 'new'
    end
  end

  private

  def find_site
    Site.find(params[:site_id])
  end

  def cluster_params
    params.require(:cluster).permit(:name, :description, :support_type)
  end
end
