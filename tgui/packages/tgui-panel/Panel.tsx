/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { useAtom, useAtomValue } from 'jotai';
import { Pane } from 'tgui/layouts';
import { Box, Button, Section, Stack } from 'tgui-core/components';
import { visibleAtom } from './audio/atoms';
import { NowPlayingWidget } from './audio/NowPlayingWidget';
import { ChatPanel } from './chat/ChatPanel';
import { ChatTabs } from './chat/ChatTabs';
import { useChatPersistence } from './chat/use-chat-persistence';
import { emotesAtom } from './emotes/atom'; // BANDASTATION ADD  - Emote Panel
import { EmotePanel } from './emotes/EmotePanel'; // BANDASTATION ADD  - Emote Panel
import { gameAtom } from './game/atoms';
import { useKeepAlive } from './game/use-keep-alive';
import { Notifications } from './Notifications';
import { PingIndicator } from './ping/PingIndicator';
import { ReconnectButton } from './reconnect';
import { settingsVisibleAtom } from './settings/atoms';
import { SettingsPanel } from './settings/SettingsPanel';
import { useSettings } from './settings/use-settings';

export function Panel(props) {
  const [emotes, setEmotes] = useAtom(emotesAtom); // BANDASTATION ADD  - Emote Panel
  const [audioVisible, setAudioVisible] = useAtom(visibleAtom);
  const game = useAtomValue(gameAtom);
  const { settings } = useSettings();
  const [settingsVisible, setSettingsVisible] = useAtom(settingsVisibleAtom);

  // BANDASTATION ADD  - Emote Panel
  const toggleEmotes = () =>
    setEmotes((prev) => ({
      ...prev,
      visible: !prev.visible,
    }));

  useChatPersistence();
  useKeepAlive();

  return (
    <Pane
      className="BandaCyberPanel"
      theme={settings.theme}
      canSuspend={false}
    >
      <Stack fill vertical g={0.75}>
        <Stack.Item>
          <Section fitted className="BandaCyberPanel__Header">
            <Stack align="center" className="BandaCyberPanel__HeaderRow">
              <Stack.Item grow minWidth={0}>
                <Box className="BandaCyberPanel__TabsFrame">
                  <ChatTabs />
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Box className="BandaCyberPanel__Controls">
                  <PingIndicator />
                  {/* BANDASTATION ADD START - Emote Panel */}
                  <Button
                    color="grey"
                    selected={emotes.visible}
                    icon="face-grin-beam"
                    tooltip="Панель эмоций"
                    tooltipPosition="bottom-start"
                    onClick={toggleEmotes}
                  />
                  {/* BANDASTATION ADD END - Emote Panel */}
                  <Button
                    color="grey"
                    selected={audioVisible}
                    icon="music"
                    tooltip="Проигрыватель музыки"
                    tooltipPosition="bottom-start"
                    onClick={() => setAudioVisible((v) => !v)}
                  />
                  <Button
                    icon={settingsVisible ? 'times' : 'cog'}
                    selected={settingsVisible}
                    tooltip={
                      settingsVisible ? 'Закрыть настройки' : 'Открыть настройки'
                    }
                    tooltipPosition="bottom-start"
                    onClick={() => setSettingsVisible((v) => !v)}
                  />
                </Box>
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
        {/* BANDASTATION ADD START - Emote Panel */}
        {emotes.visible && (
          <Stack.Item>
            <Section className="BandaCyberPanel__Drawer" title="Эмоции">
              <EmotePanel />
            </Section>
          </Stack.Item>
        )}
        {/* BANDASTATION ADD END - Emote Panel */}
        {audioVisible && (
          <Stack.Item>
            <Section className="BandaCyberPanel__Drawer" title="Аудио">
              <NowPlayingWidget />
            </Section>
          </Stack.Item>
        )}
        {settingsVisible && (
          <Stack.Item>
            <Box className="BandaCyberPanel__SettingsFrame">
              <SettingsPanel />
            </Box>
          </Stack.Item>
        )}
        <Stack.Item grow minHeight={0}>
          <Section
            fill
            fitted
            position="relative"
            className="BandaCyberPanel__ChatBox"
          >
            <Box className="BandaCyberPanel__ChatTitle">Консоль сообщений</Box>
            <Pane.Content scrollable id="chat-pane">
              <ChatPanel lineHeight={settings.lineHeight} />
            </Pane.Content>
            <Notifications>
              {game.connectionLostAt && (
                <Notifications.Item rightSlot={<ReconnectButton />}>
                  Либо вы находитесь AFK, испытываете задержку, либо соединение
                  прервано.
                </Notifications.Item>
              )}
              {game.roundRestartedAt && (
                <Notifications.Item>
                  Соединение было закрыто, так как сервер перезапускается.
                  Пожалуйста, подождите, пока вы автоматически восстановите
                  подключение.
                </Notifications.Item>
              )}
            </Notifications>
          </Section>
        </Stack.Item>
      </Stack>
    </Pane>
  );
}
