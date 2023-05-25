package main

import (
    "bufio"
    "encoding/json"
    "flag"
    "fmt"
    "io/ioutil"
    "log"
    "math/rand"
    "net/http"
    "os"
    "regexp"
    "strings"
    "time"

    "golang.org/x/net/proxy"
)

type attrStruct struct {
    Address     string  `json:"address"`
    Name        string  `json:"name"`
    CN          string  `json:"cn"`
    ID          string  `json:"id"`

    Adate       string  `json:"adate"`
    AnnoText    string  `json:"anno_text"`
    AreaType    string  `json:"area_type"`
    AreaUnit    string  `json:"area_unit"`
    AreaValue   float32 `json:"area_value"`
    CadCost     float32 `json:"cad_cost"`
    CadRecDate  string  `json:"cad_record_date"`
    CadUnit     string  `json:"cad_unit"`
    Category    string  `json:"category_type"`
    DateCost    string  `json:"date_cost"`
    DateCreate  string  `json:"date_create"`
    FP          string  `json:"fp"`
    Kvartal     string  `json:"kvartal"`
    KvartalCN   string  `json:"kvartal_cn"`
    Okrug       string  `json:"okrug"`
    OkrugCN     string  `json:"okrug_cn"`
    PubDate     string  `json:"pubdate"`
    Rayon       string  `json:"rayon"`
    RayonCN     string  `json:"rayon_cn"`
    Reg         int     `json:"reg"`
    Rifr        string  `json:"rifr"`
    RightsReg   int     `json:"rights_reg"`
    Sale        string  `json:"sale"`
    Statecd     string  `json:"statecd"`
    UtilByDoc   string  `json:"util_by_doc"`
    UtilCode    string  `json:"util_code"`
}

type objStruct struct {
    Geo         int     `json:"geo"`
    Total       int     `json:"total"`
}

type statStruct struct {
    Kvartal     objStruct       `json:"kvartal"`
    Parcel      objStruct       `json:"parcel"`
    SpecZone    objStruct       `json:"special_zone"`
    TerZone     objStruct       `json:"ter_zone"`
    ZOUIT       objStruct       `json:"zouit"`
}

type featureStruct struct {
    Attrs       attrStruct      `json:"attrs"`
    Stat        statStruct      `json:"stat"`
    TypeID      int             `json:"type"`
}

type searchStruct struct {
    Features    []featureStruct `json:"features"`
    Status      int             `json:"status"`
    Note        string          `json:"note"`
}

type dataStruct struct {
    Feature     featureStruct   `json:"feature"`
    Status      int             `json:"status"`
    Note        string          `json:"note"`
}


type replaceStruct struct {
    Pattern     string          `json:"pattern"`
    Replace     string          `json:"replace"`
}

type proxyStruct struct {
    URL         string          `json:"url"`
    Replaces    []replaceStruct `json:"replaces"`
}

type torInfoStruct struct {
    Origin      string          `json:"origin"`
}

type httpStruct struct {
    Timeout     int             `json:"timeout"`
    Try         int             `json:"try"`
    Delay       int             `json:"delay"`
    Tor         string          `json:"tor"`
}

type envStruct struct {
    HTTP        httpStruct      `json:"http"`
    UserAgents  []string        `json:"user-agents"`
    Proxies     []proxyStruct   `json:"proxies"`
}

var reportPeriod  int
var debug         bool
var phase         string
var TZ            string
var UA            string
var dstFilename   string
var dstPath       string
var envFilename   string
var httpClient    *http.Client
var cnRE          *regexp.Regexp

var env           envStruct

var proxyID = -1
var proxies []proxyStruct

var lastDownload  int


func init() {
    flag.BoolVar(&debug,                "debug",        false,          "debug mode")
    flag.IntVar(&reportPeriod,          "period",       100,            "count off objects to show report")
    flag.StringVar(&dstFilename,        "cache",        "cache.csv",    "cache filename")
    flag.StringVar(&dstPath,            "path",         ".",            "destination path to store JSON files")
    flag.StringVar(&envFilename,        "env",          "env.json",     "environment JSON file")
    flag.StringVar(&TZ,                 "tz",           "",             "tz cadnum, ex 56:01")
    flag.StringVar(&UA,                 "useragent",    "",             "HTTP user-agent")
    flag.StringVar(&phase,              "phase",        "start",        "pump phase: start, harvest")

    cnRE = regexp.MustCompile(`(:)`)

    env = envStruct{}
    proxies = []proxyStruct{}

    rand.Seed(time.Now().Unix())
}

func initProxy() {
    timeout := time.Duration(env.HTTP.Timeout) * time.Second

    if env.HTTP.Tor == "" {
        httpClient = &http.Client{
            Timeout: timeout,
        }
    } else {
        dialer, err := proxy.SOCKS5("tcp", env.HTTP.Tor, nil, proxy.Direct)
        if err != nil {
            log.Fatal(err)
        }

        tr := &http.Transport{
            Dial: dialer.Dial,
        }

        httpClient = &http.Client{
            Transport: tr,
            Timeout: timeout,
        }

        getTorInfo()
    }
}

func readJSONfile(filename string, variable interface{}) {
    file, err := ioutil.ReadFile(filename)
    if err == nil {
        err = json.Unmarshal(file, variable)
        if err != nil {
            log.Printf("Failed JSON decode: %s", err)
        }
    } else {
        log.Printf("Failed read file '%s': %v", filename, err)
    }
}

func initEnv() {
    readJSONfile(envFilename, &env)
    initProxy()
}

func download(url string) (string, error) {
    body := ""

    now := int(time.Now().Unix())
    if lastDownload + env.HTTP.Delay > now {
        pause := time.Duration(lastDownload + env.HTTP.Delay - now)
        if debug {
            log.Printf("Pause %d second(s) before next request", pause)
        }
        time.Sleep(pause * time.Second)
    }
    lastDownload = int(time.Now().Unix())

    if proxyID > -1 && proxyID < len(proxies) {
        url = fmt.Sprintf(proxies[proxyID].URL, url)
        if len(proxies[proxyID].Replaces) > 0 {
            for _, item := range proxies[proxyID].Replaces {
                proxyRE := regexp.MustCompile(item.Pattern)
                url = proxyRE.ReplaceAllString(url, item.Replace)
            }
        }
        log.Printf("Request via proxy: %s", url)
    }

    UserAgent := UA
    if UserAgent == "" {
        UserAgent = env.UserAgents[rand.Intn(len(env.UserAgents))]
    }

    request, err := http.NewRequest("GET", url, nil)
    if err == nil {
        request.Header.Set("User-Agent", UserAgent)

        response, err := httpClient.Do(request)
        if err == nil {
            defer response.Body.Close()
            bodyBytes, err := ioutil.ReadAll(response.Body)
            if err == nil {
                body = string(bodyBytes)
            }
        }
    }

    return body, err
}

func getTorInfo() {
    data, err := download("https://httpbin.org/ip")
    if err == nil {
        info := torInfoStruct{}
        err = json.Unmarshal([]byte(data), &info)
        if err == nil {
            if debug {
                log.Printf("Tor IP address: %s", info.Origin)
            }
        } else {
            log.Printf("Failed JSON decode: %s (%s)", err, data)
        }
    } else {
        log.Printf("Failed get info via TOR: ", err)
    }
}

func getCadNumList(tz dataStruct) bool {
    searchRes := searchStruct{}

    limit := 10
    skip := 0
    try := 0
    count := 0
    cn := tz.Feature.Attrs.ID
    uri := "http://pkk5.rosreestr.ru/api/features/1?text=%D0%92%20%D0%B3%D1%80%D0%B0%D0%BD%D0%B8%D1%86%D0%B0%D1%85%20%D1%80%D0%B0%D0%B9%D0%BE%D0%BD%D0%B0%20"

    if debug {
        log.Printf("Create cache file '%s'...", dstFilename)
    }
    fileHandle, err := os.Create(dstFilename)
    if err != nil {
        log.Printf("Failed create file '%s': %s", dstFilename, err)
        return false
    }
    defer fileHandle.Close()

    if debug {
        log.Printf("Searching objects for TZ %s...", cn)
    }
    for {
        try = try + 1
        url := fmt.Sprintf("%s%s&tolerance=2048&limit=%d&sqo=%s&sqot=3&skip=%d", uri, cn, limit, cn, skip)

        res, err := download(url)
        if err == nil {
            err = json.Unmarshal([]byte(res), &searchRes)
            if err == nil {
                if searchRes.Status == 200 {
                    if len(searchRes.Features) > 0 {
                        for _, feature := range searchRes.Features {
                            if strings.Index(feature.Attrs.ID, cn) > -1 {
                                _, err := fileHandle.WriteString(fmt.Sprintf("%d;%+v\n", feature.TypeID, feature.Attrs.ID))
                                if err != nil {
                                    log.Printf("Error write to file '%s': %s", dstFilename, err)
                                }
                                count = count + 1
                                if debug {
                                    if count % reportPeriod == 0 {
                                        log.Printf("Getted %d objects", count)
                                    }
                                }
                            } else {
                                return true
                            }
                        }
                        skip = skip + limit
                        try = 0
                    } else {
                        break
                    }
                } else {
                    log.Printf("%d: %s\n", searchRes.Status, searchRes.Note)
                }
            } else {
                log.Printf("Failed JSON decode: %s", err)
            }
        } else {
            log.Printf("Failed download: %s", err)
        }

        if try == env.HTTP.Try {
            log.Printf("Number of attempts exceeded (%d)", env.HTTP.Try)
            break
        }
    }

    return false
}

func getObjectInfo(objectType, cn string) (string, dataStruct) {
    url := fmt.Sprintf("http://pkk5.rosreestr.ru/api/features/%s/%s", objectType, cn)

    data := ""
    result := dataStruct{}
    if debug {
        log.Printf("Try do download object: %s", cn)
    }
    for {
        empty := 0
        for try := 0; try < env.HTTP.Try; try++ {
            res, err := download(url)
            if err == nil {
                err = json.Unmarshal([]byte(res), &result)
                if err == nil {
                    if result.Status == 200 {
                        data = res
                        break
                    } else {
                        log.Printf("%d: %s\n", result.Status, result.Note)
                    }
                } else {
                    if res == "" {
                        empty = empty + 1
                    }
                    log.Printf("Failed JSON decode: %s (%s)", err, res)
                }
            } else {
                log.Printf("Failed download: %s", err)
            }
        }

        if empty == env.HTTP.Try {
            if proxyID == -1 {
                if env.HTTP.Tor == "" {
                    log.Println("PKK5 banned my IP")
                } else {
                    log.Fatal("PKK5 banned TOR")
                }
            } else {
                log.Printf("PKK5 banned proxy %s", proxies[proxyID].URL)
            }

            proxyID = proxyID + 1
            if proxyID == len(proxies) {
                log.Fatal("PKK5 banned all proxies")
            }
        } else {
            break
        }
    }

    return data, result
}

func getObjectFilename(cn string) string {
    return fmt.Sprintf("%s/%s.json", dstPath, cnRE.ReplaceAllString(cn, "_"))
}

func storeObjectInfo(cadnum, data string) {
    result := dataStruct{}
    err := json.Unmarshal([]byte(data), &result)
    if err == nil {
        cn := result.Feature.Attrs.CN
        if cn != "" {
            cn = result.Feature.Attrs.ID
        }
        if cn == "" {
            log.Printf("Empty CN and ID of object: %+v (%s)\n", result, data)
            if cadnum == "" {
                return
            } else {
                cn = cadnum
            }
        }

        filename := getObjectFilename(cn)
        fileHandle, err := os.Create(filename)
        if err != nil {
            log.Printf("Failed create file '%s': %s", filename, err)
            return
        }
        defer fileHandle.Close()

        _, err = fileHandle.WriteString(data)
        if err != nil {
            log.Printf("Error write to file '%s': %s", filename, err)
        }
    }
}

func checkObjectFileExists(cn string) bool {
    _, err := os.Stat(getObjectFilename(cn))

    return err == nil
}

func getData() bool {
    fileHandle, err := os.Open(dstFilename)
    if err != nil {
        log.Printf("Failed open to read file '%s': %s", dstFilename, err)
        return false
    }
    defer fileHandle.Close()

    scanner := bufio.NewScanner(fileHandle)

    count := 0
    skip := 0
    for scanner.Scan() {
        line := scanner.Text()
        fields := strings.Split(line, ";")
        if checkObjectFileExists(fields[1]) {
            skip = skip + 1
            if debug {
                if skip % reportPeriod == 0 {
                    log.Printf("Skipped %d objects", skip)
                }
            }
            continue
        }
        data, res := getObjectInfo(fields[0], fields[1])
        if res.Status == 200 {
            storeObjectInfo(fields[1], data)
            count = count + 1
            if debug {
                if count % reportPeriod == 0 {
                    log.Printf("Getted %d objects info", count)
                }
            }
        }
    }

    return true
}

func getTZInfo(cn string) dataStruct {
    result := dataStruct{}

    if debug {
        log.Printf("Getting TZ info %s...", cn)
    }

    url := fmt.Sprintf("http://pkk5.rosreestr.ru/api/features/3/%s", cn)

    res, err := download(url)
    if err == nil {
        err = json.Unmarshal([]byte(res), &result)
        if err == nil {
            if result.Status != 200 {
                log.Printf("%d: %s\n", result.Status, result.Note)
            } else {
                storeObjectInfo(cn, res)
            }
        } else {
            log.Println(err)
        }
    } else {
        log.Println(err)
    }

    return result
}

func main() {
    flag.Parse()

    initEnv()

    if phase == "start" {
        if TZ == "" {
            log.Printf("tz is required parameter")
            return
        }

        tz := getTZInfo(TZ)
        if tz.Status == 200 {
            getCadNumList(tz)
            phase = "harvest"
        }
    }

    if phase == "harvest" {
        getData()
    }
}
