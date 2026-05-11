/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { useAtom } from 'jotai';
import { Box, Button, Stack, Tabs } from 'tgui-core/components';
import { settingsVisibleAtom } from '../settings/atoms';
import { useChatPages } from './use-chat-pages';

type UnreadCountWidgetProps = {
  value: number;
};

function UnreadCountWidget(props: UnreadCountWidgetProps) {
  const { value } = props;

  return <Box className="UnreadCount">{Math.min(value, 99)}</Box>;
}

const pageLabel: Record<string, string> = {
  Status: 'Статус',
  Admin: 'Администрация',
  Debug: 'Логи',
  OOC: 'OOC',
  IC: 'IC',
  Server: 'Сервер',
  Tickets: 'Билеты',
  MC: 'MC',
  Special: 'Special',
};

function normalizePageName(name: string) {
  return pageLabel[name] ?? name;
}

export function ChatTabs(props) {
  const { addChatPage, changeChatPage, pages, pagesRecord, currentPageId } =
    useChatPages();

  const [, setSettingsVisible] = useAtom(settingsVisibleAtom);

  return (
    <Stack align="center" className="BandaCyberTabs">
      <Stack.Item grow minWidth={0}>
        <Tabs scrollable textAlign="center" className="BandaCyberTabs__List">
          {pages.map((page) => {
            const actual = pagesRecord[page];
            return (
              <Tabs.Tab
                key={page}
                selected={page === currentPageId}
                className="BandaCyberTabs__Tab"
                onClick={() => changeChatPage(actual)}
              >
                {normalizePageName(actual.name)}
                {!actual.hideUnreadCount && actual.unreadCount > 0 && (
                  <UnreadCountWidget value={actual.unreadCount} />
                )}
              </Tabs.Tab>
            );
          })}
        </Tabs>
      </Stack.Item>
      <Stack.Item>
        <Button
          className="BandaCyberTabs__Add"
          color="transparent"
          icon="plus"
          onClick={() => {
            addChatPage();
            setSettingsVisible(true);
          }}
        />
      </Stack.Item>
    </Stack>
  );
}
