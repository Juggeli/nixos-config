{ lib, inputs, snowfall-inputs }:

{
  override-meta = meta: package:
    package.overrideAttrs (_: {
      inherit meta;
    });
}
