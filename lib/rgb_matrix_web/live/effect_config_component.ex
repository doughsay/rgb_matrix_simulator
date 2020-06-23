defmodule RGBMatrixWeb.EffectConfigComponent do
  use RGBMatrixWeb, :live_component

  @mapping %{
    RGBMatrix.Effect.Config.Option => RGBMatrixWeb.EffectConfigOptionComponent,
    RGBMatrix.Effect.Config.Integer => RGBMatrixWeb.EffectConfigIntegerComponent
  }

  def component_for(module) do
    Map.fetch!(@mapping, module)
  end
end
