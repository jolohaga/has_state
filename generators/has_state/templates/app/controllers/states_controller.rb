class StatesController < ApplicationController
  # GET /states
  # GET /states.xml
  def index
    @stateful_entity = find_stateful_entity
    @states = @stateful_entity.states
  end
  
  # DELETE /states/1
  # DELETE /states/1.xml
  def destroy
    @state = State.find(params[:id],:include => :stateful_entity)
    @title = @state.stateful_entity
    @state.destroy

    respond_to do |format|
      format.html { redirect_to(title_states_path(@title)) }
      format.xml  { head :ok }
    end
  end
  
  private
  def find_stateful_entity
    params.each do |name,value|
      if name =~ /(.+)_id$/
        return $1.classify.constantize.find(value,:include => :states)
      end
    end
  end
end