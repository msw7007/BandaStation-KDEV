import { ByondUi } from 'tgui-core/components';

export const CharacterPreview = (props: {
  height: string;
  id: string;
  transparent?: boolean;
  width?: string;
}) => {
  return (
    <ByondUi
      width={props.width ?? '220px'}
      height={props.height}
      params={{
        id: props.id,
        type: 'map',
        ...(props.transparent
          ? {
              background: 'transparent',
              background_color: 'transparent',
              backgroundColor: 'transparent',
              transparent: true,
            }
          : {}),
      }}
    />
  );
};
