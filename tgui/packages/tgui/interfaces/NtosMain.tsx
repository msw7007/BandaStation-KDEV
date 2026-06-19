import { Icon } from 'tgui-core/components';

import { useBackend } from '../backend';
import { NtosWindow } from '../layouts';
import type { NTOSData } from '../layouts/NtosWindow';

export enum alert_relevancies {
  ALERT_RELEVANCY_SAFE,
  ALERT_RELEVANCY_WARN,
  ALERT_RELEVANCY_PERTINENT,
}

export const NtosMain = (props) => {
  const { act, data } = useBackend<NTOSData>();
  const {
    alert_style,
    alert_color,
    alert_name,
    PC_device_theme,
    show_imprint,
    programs = [],
    has_light,
    light_on,
    comp_light_color,
    removable_media = [],
    login,
    proposed_login,
    pai,
    can_write_crypto_key,
    crypto_key_target,
  } = data;
  const headerPrograms = programs.filter((program) => program.header_program);
  const regularPrograms = programs.filter((program) => !program.header_program);
  const title =
    (PC_device_theme === 'syndicate' && 'Syndix Главное Меню') ||
    'NtOS Главное Меню';

  return (
    <NtosWindow title={title} width={400} height={500} z>
      <NtosWindow.Content scrollable className="CyberpunkPanel StyleGuide">
        <div className="StyleGuide__compactHeader">
          <div>
            <div className="StyleGuide__eyebrow">CityLink</div>
            <h1>{title}</h1>
          </div>
          <div
            className={[
              'StyleGuide__statusPill',
              alert_style === alert_relevancies.ALERT_RELEVANCY_PERTINENT &&
                'danger',
            ]
              .filter(Boolean)
              .join(' ')}
            style={{
              borderColor: alert_color,
              color:
                alert_style === alert_relevancies.ALERT_RELEVANCY_SAFE
                  ? alert_color
                  : undefined,
            }}
          >
            {alert_name}
          </div>
        </div>

        {!!headerPrograms.length && (
          <div className="StyleGuide__quickbar">
            {headerPrograms.map((app) => (
              <button
                key={app.name}
                type="button"
                className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
                onClick={() => act('PC_runprogram', { name: app.name })}
              >
                {!!app.icon && <Icon name={app.icon} />}
                <span>{app.desc}</span>
              </button>
            ))}
          </div>
        )}

        <div className="StyleGuide__blockShell">
          <div className="StyleGuide__blockTitle">Детали</div>
          <dl className="StyleGuide__definitionGrid">
            <dt>Имя на ID</dt>
            <dd>
              {show_imprint
                ? `${login.IDName} ${
                    proposed_login.IDName ? `(${proposed_login.IDName})` : ''
                  }`
                : (proposed_login.IDName ?? '')}
            </dd>
            <dt>Назначение</dt>
            <dd>
              {show_imprint
                ? `${login.IDJob} ${
                    proposed_login.IDJob ? `(${proposed_login.IDJob})` : ''
                  }`
                : (proposed_login.IDJob ?? '')}
            </dd>
          </dl>
          <div className="StyleGuide__actionRow StyleGuide__actionRow--four">
            <button
              type="button"
              className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
              disabled={!has_light}
              title="Цвет фонаря"
              onClick={() => act('PC_light_color')}
            >
              <i style={{ backgroundColor: comp_light_color }} />
              <span>Цвет</span>
            </button>
            <button
              type="button"
              className={[
                'StyleGuide__cutButton StyleGuide__cutButton--cyan-dark',
                light_on && 'active',
              ]
                .filter(Boolean)
                .join(' ')}
              disabled={!has_light}
              title={light_on ? 'Выключить фонарь' : 'Включить фонарь'}
              onClick={() => act('PC_toggle_light')}
            >
              <Icon name="lightbulb" />
              <span>Фонарь</span>
            </button>
            <button
              type="button"
              className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
              disabled={!proposed_login.IDInserted}
              title="Изъять ID"
              onClick={() => act('PC_Eject_Disk', { name: 'ID' })}
            >
              <Icon name="eject" />
              <span>ID</span>
            </button>
            <button
              type="button"
              className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
              disabled={!can_write_crypto_key}
              title={
                crypto_key_target
                  ? `Записать ключи на ${crypto_key_target}`
                  : 'Нужна нейропамять и вставленная ID/диск'
              }
              onClick={() => act('PC_Write_Crypto_Key')}
            >
              <Icon name="key" />
              <span>Ключи</span>
            </button>
          </div>
        </div>

        {!!removable_media.length && (
          <div className="StyleGuide__blockShell">
            <div className="StyleGuide__blockTitle">Носители</div>
            <div className="StyleGuide__listStack">
              {removable_media.map((device) => (
                <div
                  key={device}
                  className="StyleGuide__listRow StyleGuide__listRow--single"
                >
                  <button
                    type="button"
                    className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
                    disabled={!device}
                    onClick={() => act('PC_Eject_Disk', { name: device })}
                  >
                    <Icon name="eject" />
                    <span>{device}</span>
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}

        {!!pai && (
          <div className="StyleGuide__blockShell">
            <div className="StyleGuide__blockTitle">пИИ</div>
            <div className="StyleGuide__listStack">
              <div className="StyleGuide__listRow StyleGuide__listRow--single">
                <button
                  type="button"
                  className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
                  onClick={() => act('PC_Pai_Interact', { option: 'eject' })}
                >
                  <Icon name="eject" />
                  <span>Вытащить пИИ</span>
                </button>
              </div>
              <div className="StyleGuide__listRow StyleGuide__listRow--single">
                <button
                  type="button"
                  className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
                  onClick={() => act('PC_Pai_Interact', { option: 'interact' })}
                >
                  <Icon name="cat" />
                  <span>Настроить пИИ</span>
                </button>
              </div>
            </div>
          </div>
        )}

        <div className="StyleGuide__blockShell">
          <div className="StyleGuide__blockTitle">Программы</div>
          <div className="StyleGuide__listStack">
            {regularPrograms.map((program) => (
              <div
                key={program.name}
                className={[
                  'StyleGuide__listRow',
                  !program.running && 'StyleGuide__listRow--single',
                  program.alert && 'StyleGuide__listRow--alert',
                ]
                  .filter(Boolean)
                  .join(' ')}
              >
                <button
                  type="button"
                  className="StyleGuide__cutButton StyleGuide__cutButton--cyan-dark"
                  onClick={() => act('PC_runprogram', { name: program.name })}
                >
                  {!!program.icon && <Icon name={program.icon} />}
                  <span>{program.desc}</span>
                </button>
                {!!program.running && (
                  <button
                    type="button"
                    className="StyleGuide__iconButton StyleGuide__iconButton--red StyleGuide__iconButton--compact"
                    title="Закрыть программу"
                    onClick={() => act('PC_killprogram', { name: program.name })}
                  >
                    <Icon name="times" />
                  </button>
                )}
              </div>
            ))}
            {!regularPrograms.length && (
              <div className="StyleGuide__placeholder">
                Установленных приложений нет.
              </div>
            )}
          </div>
        </div>
      </NtosWindow.Content>
    </NtosWindow>
  );
};
