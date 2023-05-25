/*
 * LedgerLifeView.java
 */

package ledgerlife;

import com.sun.org.apache.xerces.internal.impl.dv.util.Base64;
import java.awt.AWTException;
import java.awt.Color;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.MalformedURLException;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.jdesktop.application.Action;
import org.jdesktop.application.SingleFrameApplication;
import org.jdesktop.application.FrameView;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import javax.swing.Timer;
import java.util.Calendar;
import java.text.SimpleDateFormat;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.Frame;
import java.awt.Graphics;
import java.awt.GridLayout;
import java.awt.Image;
import java.awt.Menu;
import java.awt.MenuItem;
import java.awt.PopupMenu;
import java.awt.SystemTray;
import java.awt.Toolkit;
import java.awt.TrayIcon;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.Authenticator;
import java.net.ConnectException;
import java.net.InetAddress;
import java.net.PasswordAuthentication;
import java.net.ProtocolException;
import java.net.URL;
import java.net.URLEncoder;
import java.util.Properties;
import javax.swing.BorderFactory;
import javax.swing.GroupLayout;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JPasswordField;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.JTextField;
import javax.swing.ScrollPaneLayout;

/**
 * The application's main frame.
 */
public class LedgerLifeView extends FrameView {

    public LedgerLifeView(SingleFrameApplication app) throws IOException {
        super(app);

        initComponents();

        resourceMap = org.jdesktop.application.Application.getInstance(ledgerlife.LedgerLifeApp.class).getContext().getResourceMap(LedgerLifeView.class);
        MainIcon = Toolkit.getDefaultToolkit().getImage(getApplication().getClass().getResource("images/tray.png"));
        ImagePanel panel = new ImagePanel(new ImageIcon(getApplication().getClass().getResource("images/intro.png")).getImage());
        panel.addMouseListener(new MouseListener() {
                @Override
                public void mouseClicked(MouseEvent e) {
                    if (messageTimer != null)
                        getFrame().setVisible(false);
                }

                @Override
                public void mousePressed(MouseEvent e) {
                }

                @Override
                public void mouseReleased(MouseEvent e) {
                }

                @Override
                public void mouseEntered(MouseEvent e) {
                }

                @Override
                public void mouseExited(MouseEvent e) {
                }
            });
        IntroLabel = new JLabel("Настройка компонентов...");
        IntroLabel.setFont(new Font("DejaVu Sans", 0, 10));
        IntroLabel.setForeground(Color.white);
        javax.swing.GroupLayout layout = new GroupLayout(panel);
        panel.setLayout(layout);

        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addGap(20, 20, 20)
                .addComponent(IntroLabel)
                .addContainerGap(255, Short.MAX_VALUE))
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                .addContainerGap(127, Short.MAX_VALUE)
                .addComponent(IntroLabel)
                .addGap(20, 20, 20))
        );

        getFrame().getContentPane().add(panel);
        getFrame().setPreferredSize(panel.getSize());
        getFrame().setMinimumSize(panel.getSize());
        getFrame().setMaximumSize(panel.getSize());
        getFrame().setSize(panel.getSize());
        getFrame().setAlwaysOnTop(true);
        getFrame().setResizable(false);
        getFrame().setUndecorated(true);
        getFrame().setIconImage(MainIcon);
        getFrame().pack();
        Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
        Dimension windowSize = getFrame().getSize();
        getFrame().setLocation(Math.max(0, (screenSize.width  - windowSize.width) / 2),
                                Math.max(0, (screenSize.height - windowSize.height) / 2));

        Timer timer = new Timer(100, new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                try {
                    InitElements();
                } catch (IOException ex) {
                    Logger.getLogger(LedgerLifeView.class.getName()).log(Level.SEVERE, null, ex);
                }
            }
        });
        timer.setRepeats(false);
        timer.start();
    }

    class ImagePanel extends JPanel {
        private Image img;

        public ImagePanel(String img) {
            this(new ImageIcon(img).getImage());
        }

        public ImagePanel(Image img) {
            this.img = img;
            Dimension size = new Dimension(img.getWidth(null), img.getHeight(null));
            setPreferredSize(size);
            setMinimumSize(size);
            setMaximumSize(size);
            setSize(size);
            setLayout(null);
        }

        @Override
        public void paintComponent(Graphics g) {
            g.drawImage(img, 0, 0, null);
        }
    }

    public void SetIntroStatus(String text) {
        IntroLabel.setText(text);
        IntroLabel.repaint();
        getFrame().repaint();
    }

    public void InitElements() throws IOException {
        System.setProperty("http.maxRedirects", "2");

        SetIntroStatus("Чтение файла конфигурации...");
        String configFileName = "ledgerlife.config";
        String Login = "";
        String Pass = "";
        Boolean Store = false;
        Integer Autologin = 0;

        Properties configFile = new Properties();
        File f = new File(configFileName);
        if (f.exists())
        {
            configFile.load(new FileInputStream(configFileName));
            Login = configFile.getProperty("login") != null?configFile.getProperty("login"):"";
            Pass = configFile.getProperty("password");
            if (Pass != null)
                Pass = new String(Base64.decode(Pass));
            else
                Pass = "";
            String tmp = configFile.getProperty("autologin");
            if (tmp != null)
                Autologin = Integer.parseInt(tmp);
            ServerIP = configFile.getProperty("ip");
            Store = !Pass.equals("");
        }

        SetIntroStatus("Поиск сервера...");
        URL localUrl;
        boolean flag = false;
        if (ServerIP != null) {
            localUrl = new URL("http://"+ServerIP+"/ledgerlife");
            try {
                localUrl.getContent();
                flag = true;
            } catch (ConnectException ex) {
            } catch (IOException ex) {
            }
        }
        if (!flag) {
            ServerIP = "192.168.222.2";
            localUrl = new URL("http://"+ServerIP+"/ledgerlife");
            try {
                localUrl.getContent();
                flag = true;
            } catch (ConnectException ex) {
                ServerIP = "10.33.100.250";
            } catch (IOException ex) {
                ServerIP = "10.33.100.250";
            }
            if (!flag) {
                localUrl = new URL("http://"+ServerIP+"/ledgerlife");
                try {
                    localUrl.getContent();
                    flag = true;
                } catch (ConnectException ex) {
                } catch (IOException ex) {
                }
            }
        }
        if (!flag) {
            System.out.println("Connection to server failed.");
            System.exit(0);
        }
        jobURL = new URL("http://"+ServerIP+"/cgi-ledgerlife/status.cgi?status=1");
        reportURL = new URL("http://"+ServerIP+"/cgi-ledgerlife/user.cgi?act=report");
        statusURL = new URL("http://"+ServerIP+"/cgi-ledgerlife/user.cgi?act=status");
        updateURL = new URL("http://"+ServerIP+"/cgi-ledgerlife/user.cgi?act=version");

        trayImage2 = Toolkit.getDefaultToolkit().getImage(getApplication().getClass().getResource("images/tray2.png"));

        String hostName = InetAddress.getLocalHost().getCanonicalHostName();

        String[] tmp = Pass.split(":");
        if (tmp.length == 2 && tmp[0].equals(hostName))
            Pass = tmp[1];
        else
            Pass = "";

        SetIntroStatus("Настройки учетной записи...");
        JTextField user = new JTextField(Login);
        JTextField password = new JPasswordField(Pass);
        JCheckBox store = new JCheckBox("", Store);
        JCheckBox autologin = new JCheckBox("", Autologin == 1);
        JPanel panel = new JPanel(new GridLayout(4,2));
        panel.add(new JLabel("Логин"));
        panel.add(user);
        panel.add(new JLabel("Пароль"));
        panel.add(password);
        panel.add(new JLabel("Запомнить"));
        panel.add(store);
        panel.add(new JLabel("Автоматический вход"));
        panel.add(autologin);
        flag = true;
        FIO = "";
        InputStream content;
        BufferedReader in;
        while (flag)
        {
            if (Autologin != 1)
            {
                int option = JOptionPane.showConfirmDialog(getFrame(), new Object[] { panel }, resourceMap.getString("Application.name")+" - Подключение", JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);
                if ( option == JOptionPane.CANCEL_OPTION )
                    System.exit(0);
            }
            else
                Autologin = 0;
            Authenticator.setDefault(new MyAuthenticator(user.getText(), password.getText()));

            try {
                content = (InputStream) (new URL("http://"+ServerIP+"/cgi-ledgerlife/user.cgi")).getContent();
                in = new BufferedReader(new InputStreamReader(content));
                FIO = in.readLine();
                if (System.getProperty("os.name").matches("Windows.*"))
                    FIO = new String(FIO.getBytes("cp1251"), "utf8");
                flag = false;
            } catch(ProtocolException e) {
            }
        }

        if (store.isSelected())
        {
            configFile.setProperty("ip", ServerIP);
            configFile.setProperty("login", user.getText());
            configFile.setProperty("password", Base64.encode((hostName + ":" + password.getText()).getBytes()));
            configFile.setProperty("autologin", autologin.isSelected()?"1":"0");
            configFile.store(new FileOutputStream("ledgerlife.config"), "LedgerLife configuration file");
        }
        else {
            if (Store)
                f.delete();
            configFile.setProperty("ip", ServerIP);
            configFile.store(new FileOutputStream("ledgerlife.config"), "LedgerLife configuration file");
        }

        content = (InputStream) (new URL("http://"+ServerIP+"/cgi-ledgerlife/user.cgi?act=begin")).getContent();
        in = new BufferedReader(new InputStreamReader(content));
        String temp = in.readLine();
        if (temp != null && !temp.equals("") && temp.matches("\\d+"))
            BeginTime = Integer.parseInt(temp);
        content = (InputStream) (new URL("http://"+ServerIP+"/cgi-ledgerlife/user.cgi?act=end")).getContent();
        in = new BufferedReader(new InputStreamReader(content));
        temp = in.readLine();
        if (temp != null && !temp.equals("") && temp.matches("\\d+"))
            EndTime = Integer.parseInt(temp);

        SetIntroStatus("Инициализация окон...");
        if (!SystemTray.isSupported()) {
            System.out.println("SystemTray is not supported");
            return;
        }
        else {
            ActionListener reportListener = new ActionListener() {
                @Override
                public void actionPerformed(ActionEvent e) {
                    try {
                        if (Visible) {
                            JobStart();
                        }
                        ShowReport();
                    } catch (IOException ex) {
                        Logger.getLogger(LedgerLifeView.class.getName()).log(Level.SEVERE, null, ex);
                    }
                }
            };
            taskHash = GetTaskHash();

            final PopupMenu popup = new PopupMenu();
            MenuItem reportItem = new MenuItem(resourceMap.getString("Labels.toReport"));
            reportItem.addActionListener(reportListener);
            stateMenuItem = new MenuItem(resourceMap.getString("Labels.toLeave"));
            stateMenuItem.addActionListener(new ActionListener() {
                                            @Override
                                            public void actionPerformed(ActionEvent e) {
                    try {
                        ToggleState();
                    } catch (MalformedURLException ex) {
                        Logger.getLogger(LedgerLifeView.class.getName()).log(Level.SEVERE, null, ex);
                    } catch (IOException ex) {
                        Logger.getLogger(LedgerLifeView.class.getName()).log(Level.SEVERE, null, ex);
                    }
                                            }});
            Menu taskItem = new Menu(resourceMap.getString("Labels.tasks"));

            ActionListener openWebLL = new ActionListener() {
                                            @Override
                                            public void actionPerformed(ActionEvent e) {
                    try {
                        java.awt.Desktop.getDesktop().browse(java.net.URI.create("http://" + ServerIP + "/ledgerlife"));
                    } catch (IOException ex) {
                        Logger.getLogger(LedgerLifeView.class.getName()).log(Level.SEVERE, null, ex);
                    }
                                            }};
            currentTaskMenuItem = new MenuItem(resourceMap.getString("Labels.current")+" ()");
            currentTaskMenuItem.addActionListener(new ActionListener() {
                @Override
                public void actionPerformed(ActionEvent e) {
                    try {
                        CheckCurrentTasks();
                    } catch (MalformedURLException ex) {
                        Logger.getLogger(LedgerLifeView.class.getName()).log(Level.SEVERE, null, ex);
                    } catch (IOException ex) {
                        Logger.getLogger(LedgerLifeView.class.getName()).log(Level.SEVERE, null, ex);
                    }
                }
            });
            todayTaskMenuItem = new MenuItem(resourceMap.getString("Labels.today")+" ()");
            todayTaskMenuItem.addActionListener(new ActionListener() {

                @Override
                public void actionPerformed(ActionEvent e) {
                    try {
                        CheckTodayTasks();
                    } catch (MalformedURLException ex) {
                        Logger.getLogger(LedgerLifeView.class.getName()).log(Level.SEVERE, null, ex);
                    } catch (IOException ex) {
                        Logger.getLogger(LedgerLifeView.class.getName()).log(Level.SEVERE, null, ex);
                    }
                }
            });
            timeoutTaskMenuItem = new MenuItem(resourceMap.getString("Labels.timeout")+" ()");
            timeoutTaskMenuItem.addActionListener(new ActionListener() {

                @Override
                public void actionPerformed(ActionEvent e) {
                    try {
                        CheckTimeoutTasks();
                    } catch (MalformedURLException ex) {
                        Logger.getLogger(LedgerLifeView.class.getName()).log(Level.SEVERE, null, ex);
                    } catch (IOException ex) {
                        Logger.getLogger(LedgerLifeView.class.getName()).log(Level.SEVERE, null, ex);
                    }
                }
            });
            failedTaskMenuItem = new MenuItem(resourceMap.getString("Labels.failed")+" ()");
            failedTaskMenuItem.addActionListener(openWebLL);
            delayTaskMenuItem = new MenuItem(resourceMap.getString("Labels.delay")+" ()");
            delayTaskMenuItem.addActionListener(openWebLL);
            UpdateTaskCounts();
            taskItem.add(timeoutTaskMenuItem);
            taskItem.add(todayTaskMenuItem);
            taskItem.add(currentTaskMenuItem);
            taskItem.addSeparator();
            taskItem.add(failedTaskMenuItem);
            taskItem.add(delayTaskMenuItem);
            MenuItem aboutItem = new MenuItem(resourceMap.getString("Labels.About"));
            aboutItem.addActionListener(new ActionListener() {
                                        @Override
                                        public void actionPerformed(ActionEvent e) {
                                            getFrame().setVisible(true);
                                        }});
            MenuItem exitItem = new MenuItem(resourceMap.getString("Labels.toQuit"));
            exitItem.addActionListener(new ActionListener() {
                                        @Override
                                        public void actionPerformed(ActionEvent e) {
                                            System.exit(0);
                                        }});
            popup.add(reportItem);
            popup.add(taskItem);
            popup.add(stateMenuItem);
            popup.addSeparator();
            popup.add(aboutItem);
            popup.addSeparator();
            popup.add(exitItem);

            trayIcon = new TrayIcon(MainIcon, "", popup);
            CheckReports(true);
            trayIcon.setImageAutoSize(true);
            trayIcon.addMouseListener(new MouseListener() {
                @Override
                public void mouseClicked(MouseEvent e) {
                    if (e.getButton() == 1 && e.getClickCount() == 2)
                        try {
                        ToggleState();
                    } catch (MalformedURLException ex) {
                        Logger.getLogger(LedgerLifeView.class.getName()).log(Level.SEVERE, null, ex);
                    } catch (IOException ex) {
                        Logger.getLogger(LedgerLifeView.class.getName()).log(Level.SEVERE, null, ex);
                    }
                }

                @Override
                public void mousePressed(MouseEvent e) {
                }

                @Override
                public void mouseReleased(MouseEvent e) {
                }

                @Override
                public void mouseEntered(MouseEvent e) {
                }

                @Override
                public void mouseExited(MouseEvent e) {
                }
            });

            final SystemTray tray = SystemTray.getSystemTray();
            try {
                tray.add(trayIcon);
            } catch (AWTException e) {
                System.out.println("TrayIcon could not be added.");
            }
        }

        JLabel reportFIOlabel = new JLabel(FIO);
        Font boldFont = new Font("DejaVu Sans", 1, 13);
        reportFIOlabel.setFont(boldFont);
        reportFIOlabel.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);

        reportArea = new JTextArea();
        Font normalFont = new Font("DejaVu Sans", 0, 13);
        reportArea.setFont(normalFont);
        reportArea.setLineWrap(true);

        JScrollPane jScrollPane1 = new JScrollPane();
        jScrollPane1.setViewportView(reportArea);

        reportPanel = new JPanel();
        javax.swing.GroupLayout layout = new GroupLayout(reportPanel);
        reportPanel.setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addComponent(reportFIOlabel, javax.swing.GroupLayout.DEFAULT_SIZE, 400, Short.MAX_VALUE)
            .addComponent(jScrollPane1, javax.swing.GroupLayout.DEFAULT_SIZE, 400, Short.MAX_VALUE)
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addComponent(reportFIOlabel)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jScrollPane1, javax.swing.GroupLayout.DEFAULT_SIZE, 127, Short.MAX_VALUE))
        );

        javax.swing.ActionMap actionMap = org.jdesktop.application.Application.getInstance(ledgerlife.LedgerLifeApp.class).getContext().getActionMap(LedgerLifeView.class, this);
        JButton button = new javax.swing.JButton();
        button.setAction(actionMap.get("JobStart"));
        button.setText(resourceMap.getString("Labels.toJob"));
        button.setToolTipText(resourceMap.getString("Labels.JobTip"));

        JLabel jobFIOlabel = new JLabel(FIO);
        jobFIOlabel.setFont(boldFont);
        jobFIOlabel.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);

        DateLabel = new javax.swing.JLabel();
        DateLabel.setText("12.12.2010 00:00:00");

        JPanel JobPanel = new JPanel();
        javax.swing.GroupLayout layout2 = new GroupLayout(JobPanel);
        JobPanel.setLayout(layout2);
        JobPanel.setBorder(BorderFactory.createLineBorder(Color.DARK_GRAY));

        layout2.setHorizontalGroup(
            layout2.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addComponent(jobFIOlabel, javax.swing.GroupLayout.DEFAULT_SIZE, 350, Short.MAX_VALUE)
            .addGroup(layout2.createSequentialGroup()
                .addComponent(DateLabel)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED, 120, Short.MAX_VALUE)
                .addComponent(button))
        );
        layout2.setVerticalGroup(
            layout2.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout2.createSequentialGroup()
                .addComponent(jobFIOlabel)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED, 0, Short.MAX_VALUE)
                .addGroup(layout2.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING)
                    .addComponent(DateLabel)
                    .addComponent(button)))
        );
        jobDialog = new Frame(resourceMap.getString("Application.name"));
        jobDialog.setSize(350, 60);
        jobDialog.setAlwaysOnTop(true);
        jobDialog.setUndecorated(true);
        jobDialog.setResizable(false);
        jobDialog.setIconImage(MainIcon);
        jobDialog.add(JobPanel);

        Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
        Dimension windowSize = jobDialog.getSize();
        X = Math.max(0, (screenSize.width  - windowSize.width) / 2);
        Y = Math.max(0, (screenSize.height - windowSize.height) / 2);
        jobDialog.setLocation(X, Y);

        taskPanel = new javax.swing.JScrollPane();
        taskPanel.setMinimumSize(new Dimension(500, 300));
        taskTextArea = new javax.swing.JTextArea();
        taskTextArea.setEditable(false);
        taskTextArea.setWrapStyleWord(true);
        taskTextArea.setAutoscrolls(false);
        taskTextArea.setMinimumSize(new Dimension(500, 300));
        taskPanel.setViewportView(taskTextArea);
        ScrollPaneLayout layoutTask = new ScrollPaneLayout();
        taskPanel.setLayout(layoutTask);
//        taskDialog = new Frame(resourceMap.getString("Application.name"));
//        taskDialog.setSize(500, 300);
//        taskDialog.setAlwaysOnTop(true);
//        taskDialog.setResizable(false);
//        taskDialog.setModalExclusionType(ModalExclusionType.TOOLKIT_EXCLUDE);
//        taskDialog.setIconImage(MainIcon);
//        taskDialog.add(taskPanel);
//        windowSize = taskDialog.getSize();
//        taskDialog.setLocation(Math.max(0, (screenSize.width  - windowSize.width) / 2),
//                                Math.max(0, (screenSize.width  - windowSize.width) / 2));

        SetIntroStatus("Инициализация уведомлений...");
        messageTimer = new Timer(60 * 1000, new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                try {
                    SetTime();
                } catch (MalformedURLException ex) {
                    Logger.getLogger(LedgerLifeView.class.getName()).log(Level.SEVERE, null, ex);
                } catch (IOException ex) {
                    Logger.getLogger(LedgerLifeView.class.getName()).log(Level.SEVERE, null, ex);
                }
            }
        });
        messageTimer.setRepeats(true);
        messageTimer.start();

        SetIntroStatus("Проверка обновлений...");
        CheckUpdates();

        SetIntroStatus("Активация присутствия на рабочем месте...");
        JobStart();

        getFrame().setVisible(false);
        IntroLabel.setText("версия " + resourceMap.getString("Application.version"));

        CheckTimeoutTasks();
        CheckTodayTasks();
        CheckNewTasks();
    }

    public void UpdateTaskCounts() throws MalformedURLException, IOException {
        currentTaskMenuItem.setLabel(resourceMap.getString("Labels.current")+" ("+GetTaskCount("current")+")");
        todayTaskMenuItem.setLabel(resourceMap.getString("Labels.today")+" ("+GetTaskCount("today")+")");
        timeoutTaskMenuItem.setLabel(resourceMap.getString("Labels.timeout")+" ("+GetTaskCount("timeout")+")");
        failedTaskMenuItem.setLabel(resourceMap.getString("Labels.failed")+" ("+GetTaskCount("failed")+")");
        delayTaskMenuItem.setLabel(resourceMap.getString("Labels.delay")+" ("+GetTaskCount("delay")+")");
    }

    public String GetTaskHash() throws MalformedURLException, IOException {
        InputStream content = (InputStream) (new URL("http://"+ServerIP+"/cgi-ledgerlife/user.cgi?act=tasks")).getContent();
        BufferedReader in = new BufferedReader(new InputStreamReader(content));
        return in.readLine();
    }

    public Integer GetTaskCount(String mode) throws MalformedURLException, IOException {
        InputStream content = (InputStream) (new URL("http://"+ServerIP+"/cgi-ledgerlife/user.cgi?act="+mode+".task")).getContent();
        BufferedReader in = new BufferedReader(new InputStreamReader(content));
        return Integer.parseInt(in.readLine());
    }

    public void ToggleState() throws MalformedURLException, IOException {
        try {
            (new URL("http://"+ServerIP+"/cgi-ledgerlife/status.cgi?status="+(Visible?"1":"0"))).getContent();
        } catch (IOException ex) {
            Logger.getLogger(LedgerLifeView.class.getName()).log(Level.SEVERE, null, ex);
        }
        if (Visible)
            HideWindow();
        else
            ShowWindow();
        stateMenuItem.setLabel(resourceMap.getString(Visible?"Labels.toJob":"Labels.toLeave"));
    }

    public void CheckUpdates() throws MalformedURLException, IOException {
        if (showedUpdate)
            return;
        String ver = resourceMap.getString("Application.version");
        String[] vers = ver.split("\\.");
        Integer cv = Integer.parseInt(vers[0])*10000+Integer.parseInt(vers[1])*100+Integer.parseInt(vers[2]);
        InputStream content = (InputStream) updateURL.getContent();
        BufferedReader in = new BufferedReader(new InputStreamReader(content));
        String version = in.readLine();
        vers = version.split("\\.");
        Integer nv = Integer.parseInt(vers[0])*10000+Integer.parseInt(vers[1])*100+Integer.parseInt(vers[2]);
        if (nv > cv)
        {
            showedUpdate = true;
            JOptionPane.showMessageDialog(getFrame(),
                                            "Имеется новая версия программы\n\n" + "Текущая версия: "+ver+"\n    Новая версия: "+version,
                                            resourceMap.getString("Application.name")+" - Обновление",
                                            JOptionPane.PLAIN_MESSAGE);
            java.awt.Desktop.getDesktop().browse(java.net.URI.create("http://" + ServerIP + "/ledgerlife/updates.html"));
        }
    }

    public void ShowReport() throws UnsupportedEncodingException, IOException {
        if (!showedReport)
        {
            reportArea.setText("");
            showedReport = true;
            JOptionPane reportPane = new JOptionPane(new Object[] { reportPanel }, JOptionPane.PLAIN_MESSAGE, JOptionPane.OK_CANCEL_OPTION);
            JDialog d = reportPane.createDialog(getFrame(), resourceMap.getString("Application.name") + " - Отчет");
            d.setAlwaysOnTop(true);
            d.setResizable(false);
            d.setVisible(true);
            while (reportPane.getValue() == JOptionPane.UNINITIALIZED_VALUE) {
                try {
                        Thread.sleep(100);
                } catch (InterruptedException ie) {
                }
            }
            if (Integer.parseInt(reportPane.getValue().toString()) == JOptionPane.OK_OPTION)
            {
                String message = reportArea.getText();
                if (message != null && !message.equals("")) {
                    (new URL("http://"+ServerIP+"/cgi-ledgerlife/reports.cgi?" +
                                "mode=ajax&act=newreport&func=&id=&task=&value=" +
                                URLEncoder.encode(reportArea.getText(), "UTF-8"))).getContent();
                    CheckReports(false);
                }
            }
            showedReport = false;
        }
    }

    public void TestStatus() throws MalformedURLException, IOException {
        InputStream content = (InputStream) statusURL.getContent();
        BufferedReader in = new BufferedReader(new InputStreamReader(content));
        int status = Integer.parseInt(in.readLine());
        if (Visible && status == 1)
            HideWindow();
        else if (!Visible && status == 0)
            ShowWindow();
    }

    public void SetTrayIcon() {
        trayIcon.setImage(Visible?trayImage2:MainIcon);
    }

    public void SetTime() throws MalformedURLException, IOException {
        int now = Integer.parseInt(nowSDF.format(Calendar.getInstance().getTime()));
        if (now >= BeginTime - BeginDelay && now <= EndTime + EndDelay)
        {
            if (!Visible)
                TestStatus();
            if (!Visible && 
                    now >= ReportBeginTime && now <= EndTime &&
                    now % 5 == 0 &&
                    !showedReport && reportCount == 0) {
                int count = GetReportsCount();
                if (count == 0)
                    ShowReport();
                else {
                    reportCount = count;
                    SetTrayToolTip();
                }
            }
            else if (now % 10 == 0) {
                CheckReports(false);
            }
            if (!Visible && 
                    now % 60 == 0 &&
                    !showedUpdate && !showedReport)
                CheckUpdates();
        }
        else
        {
                showedUpdate = false;
                reportCount = 0;
                SetTrayToolTip();
                HideWindow();
        }
        CheckNewTasks();
        CheckAlmostTasks();
        CheckHalfTasks();
    }

    public void CheckNewTasks() throws MalformedURLException, IOException {
        CheckTasks("new");
        String tmp = GetTaskHash();
        if (!taskHash.equals(tmp)) {
            UpdateTaskCounts();
            taskHash = tmp;
        }
    }

    public void CheckTasks(String mode) throws MalformedURLException, IOException {
        Integer temp = GetTaskCount(mode);
        if (temp > 0) {
            InputStream content = (InputStream) (new URL("http://"+ServerIP+"/cgi-ledgerlife/user.cgi?act=get"+mode+"task")).getContent();
            BufferedReader in = new BufferedReader(new InputStreamReader(content));
            String tmp;
            taskTextArea.setText("");
            Integer cnt = 0;
            while ((tmp = in.readLine()) != null) {
                taskTextArea.append(tmp+"\n");
                if (tmp.matches("^Сотрудник: "))
                    cnt++;
            }
            if (cnt > 0)
                JOptionPane.showMessageDialog(getFrame(), taskPanel, resourceMap.getString("Application.name") + " - " + resourceMap.getString("Tasks."+mode) + " (" + cnt + ")", JOptionPane.PLAIN_MESSAGE);
        }
    }

    public void CheckTodayTasks() throws MalformedURLException, IOException {
        CheckTasks("today");
    }

    public void CheckHalfTasks() throws MalformedURLException, IOException {
        CheckTasks("half");
    }

    public void CheckAlmostTasks() throws MalformedURLException, IOException {
        CheckTasks("almost");
    }

    public void CheckTimeoutTasks() throws MalformedURLException, IOException {
        CheckTasks("timeout");
    }

    public void CheckCurrentTasks() throws MalformedURLException, IOException {
        CheckTasks("current");
    }

    public void CheckReports(boolean flag) throws IOException {
        int count = GetReportsCount();
        if (reportCount != count) {
            reportCount = count;
            SetTrayToolTip();
        }
        else if (flag)
            SetTrayToolTip();
    }

    public int GetReportsCount() throws IOException {
        InputStream content = (InputStream) reportURL.getContent();
        BufferedReader in = new BufferedReader(new InputStreamReader(content));
        return Integer.parseInt(in.readLine());
    }

    public void SetTrayToolTip() {
        trayIcon.setToolTip(resourceMap.getString("Application.name") + " - " + FIO + (reportCount > 0?(" (" + reportCount + ")"):""));
    }

    static class MyAuthenticator extends Authenticator {
        private String username, password;

        public MyAuthenticator(String user, String pass) {
            username = user;
            password = pass;
        }

        @Override
        protected PasswordAuthentication getPasswordAuthentication() {
            return new PasswordAuthentication(username, password.toCharArray());
        }
    }

    public void ToggleWindow() {
        jobDialog.setVisible(!Visible);
        Visible = !Visible;
        SetTrayIcon();
    }

    public void HideWindow() throws MalformedURLException, IOException {
        if (Visible) {
            ToggleWindow();
            CheckTimeoutTasks();
            CheckTodayTasks();
        }
    }

    public void ShowWindow() {
        if (!Visible)
            ToggleWindow();
        DateLabel.setText(sdf.format(Calendar.getInstance().getTime()));
        jobDialog.setLocation(X, Y);
    }

    @Action
    public void JobStart() throws IOException {
        try {
            jobURL.getContent();
        } catch(IOException ex) {
            Logger.getLogger(LedgerLifeView.class.getName()).log(Level.SEVERE, null, ex);
        }
        HideWindow();
    }

    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

    }// </editor-fold>//GEN-END:initComponents

    // Variables declaration - do not modify//GEN-BEGIN:variables
    // End of variables declaration//GEN-END:variables

    private boolean Visible = false;
    private boolean showedReport = false;
    private boolean showedUpdate = false;
    private int reportCount = 0;
    private int BeginTime = 900;
    private int EndTime = 1800;
    private int BeginDelay = 100;
    private int EndDelay = 100;
    private int ReportDelay = 100;
    private int ReportBeginTime = EndTime - ReportDelay;
    private final SimpleDateFormat sdf = new SimpleDateFormat("dd.MM.yyyy HH:mm");
    private final SimpleDateFormat nowSDF = new SimpleDateFormat("HHmm");

    private Timer messageTimer;
    private URL jobURL, statusURL, reportURL, updateURL;
    private String FIO, ServerIP, taskHash;
    private TrayIcon trayIcon;
    private Image MainIcon, trayImage2;
    private JPanel reportPanel;
    private JScrollPane taskPanel;
    private JTextArea reportArea, taskTextArea;
    private JLabel DateLabel, IntroLabel;
    private Frame jobDialog;
    private org.jdesktop.application.ResourceMap resourceMap;
    private MenuItem stateMenuItem, currentTaskMenuItem, todayTaskMenuItem, timeoutTaskMenuItem, failedTaskMenuItem, delayTaskMenuItem;
    private int X, Y;
}
