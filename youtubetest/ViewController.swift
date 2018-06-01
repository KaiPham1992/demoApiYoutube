//
import GoogleAPIClientForREST
import GoogleSignIn
import UIKit
import MobileCoreServices
import SwiftyJSON
import Alamofire
import PKHUD

class ViewController: UIViewController {
    private let scopes = [kGTLRAuthScopeYouTube,kGTLRAuthScopeYouTubeForceSsl, kGTLRAuthScopeYouTubeUpload,kGTLRAuthScopeYouTubeYoutubepartner]
    
    let service : GTLRYouTubeService = GTLRYouTubeService()
    let signInButton = GIDSignInButton()
    let keyYoutube = "AIzaSyDCIqxrPaTkqM58QEHFsMfSq6cmXGXg7QQ"
    
    var listVideo = [Video]() {
        didSet {
            let index = IndexSet(integer: 1)
            tbVideo.reloadSections(index, with: .automatic)
        }
    }
    
    var listVideoSelected = [Video]()
    
    
    //My Video
    var listMyVideo = [Video]() {
        didSet {
            let index = IndexSet(integer: 0)
            tbVideo.reloadSections(index, with: .automatic)
        }
    }
    
    var listMyVideoSelected = [Video]()
    
    @IBOutlet weak var tbVideo: UITableView!
    @IBOutlet weak var tfSearch: UITextField!
    
    // can fix
    let myChannelID = "UC8PsocQtzxswSn7OVISncgg"
    
    
    // can not fix
    let urlSearch  = "https://www.googleapis.com/youtube/v3/search"
    var rootParam: [String: Any] = [
        "part": "snippet",
        "maxResults": 50,
        "key": "AIzaSyDCIqxrPaTkqM58QEHFsMfSq6cmXGXg7QQ"
    ]
    
    var urlMySearch = "https://www.googleapis.com/youtube/v3/search?part=snippet&key=AIzaSyDCIqxrPaTkqM58QEHFsMfSq6cmXGXg7QQ&maxResults=8&channelId={id}&type=video&order=date"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure Google Sign-in.
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = scopes
        GIDSignIn.sharedInstance().signInSilently()
        
        
        
        // Add the sign-in button.
        view.addSubview(signInButton)
        signInButton.center = self.view.center
        
        configureTable()
        getMyVideo { videos in
            self.listMyVideoSelected = videos
            videos.forEach({ _video in
                _video.isSelected = true
            })
            
            self.listMyVideo = videos.filter({ _video -> Bool in
                return _video.id != nil
            })
        }
    }
    
    
    
    func createList(listVideoToCreate: [Video], titlePlayList: String, completion: @escaping () -> Void) {
        
        
        let newPlaylist = GTLRYouTube_Playlist()
        newPlaylist.snippet = GTLRYouTube_PlaylistSnippet()
        newPlaylist.snippet?.title = titlePlayList
        newPlaylist.snippet?.descriptionProperty  = titlePlayList
        
        newPlaylist.status = GTLRYouTube_PlaylistStatus()
        newPlaylist.status?.privacyStatus = kGTLRYouTube_PlaylistStatus_PrivacyStatus_Public
        
        let query = GTLRYouTubeQuery_PlaylistsInsert.query(withObject: newPlaylist, part: "snippet,status")
        
        
        self.service.executeQuery(query) { (ticket, object, error) in
            guard let _object = object as? GTLRYouTube_Playlist else {
                print("Done")
                GIDSignIn.sharedInstance().signOut()
                return
            }
            
            if error == nil {
                self.insertVideo(idPlayList: _object.identifier!, listVideoToCreate: listVideoToCreate, index: 0, completion: {
                    completion()
                })
            } else {
                PopUpHelper.showMessage(message: (error?.localizedDescription)!, controller: self)
            }
            
        }
        
    }
    
    func insertVideo(idPlayList: String, listVideoToCreate: [Video], index: Int, completion: @escaping () -> Void) {
        var currentIndex = index
        
        let newPlayListItem = GTLRYouTube_PlaylistItem()
        newPlayListItem.snippet = GTLRYouTube_PlaylistItemSnippet()
        newPlayListItem.snippet?.playlistId = idPlayList
        newPlayListItem.snippet?.resourceId = GTLRYouTube_ResourceId()
        newPlayListItem.snippet?.resourceId?.kind = "youtube#video"
        newPlayListItem.snippet?.resourceId?.videoId = listVideoToCreate[index].id!
        
        let queryVideo = GTLRYouTubeQuery_PlaylistItemsInsert.query(withObject: newPlayListItem, part: "snippet")
        
        self.service.executeQuery(queryVideo, completionHandler: { (_, _, errorVideo) in
            if errorVideo == nil {
                print("Done insert video: \(listVideoToCreate[index].title!)")
                currentIndex += 1
                
                if currentIndex >= listVideoToCreate.count - 1 {
                    completion()
                } else {
                    self.insertVideo(idPlayList: idPlayList, listVideoToCreate: listVideoToCreate, index: currentIndex, completion: {
                        //done
                        completion()
                    })
                }
            } else {
                print("Error insert video")
            }
        })
    }
    
}

// MARK: Action

extension ViewController {
    @IBAction func btnCreateList() {
        
        self.listVideoSelected = self.listVideo.filter({ _video -> Bool in
            return _video.isSelected == true
        })
        
        if checkCanCreate() {
            // video to create = listMyVideoSelected + 50 video search
            var listToCreate = self.listMyVideoSelected
            
            for itemVideo in self.listVideo {
                listToCreate.append(itemVideo)
            }
            
            createOnePlaylist(listVideoToCreate: listToCreate, index: 0)
        }
    }
    
    func createOnePlaylist(listVideoToCreate: [Video], index: Int) {
        var indexCurrent = index
        self.createList(listVideoToCreate: listVideoToCreate, titlePlayList: self.listVideoSelected[index].title!) {
            indexCurrent += 1
            self.createOnePlaylist(listVideoToCreate: listVideoToCreate, index: indexCurrent)
            
            if indexCurrent == 9 {
                print("Ok Done")
                GIDSignIn.sharedInstance().signOut()
                return
            }
        }
    }
    
    
    func checkCanCreate() -> Bool {
        if self.listMyVideoSelected.count <= 0 {
            PopUpHelper.showMessage(message: "Chọn Video của bạn đi kìa!", controller: self)
            return false
        }
        
        if self.listVideoSelected.count < 10 {
            PopUpHelper.showMessage(message: "Chọn 10 Video làm tiêu đề cho playlist nào!", controller: self)
            return false
        }
        
        if self.listVideoSelected.count > 10 {
            PopUpHelper.showMessage(message: "Không được chọn nhiều hơn 10 Video!", controller: self)
            return false
        }
        
        return true
    }
    
    @IBAction func btnSearchVideo() {
        self.tfSearch.endEditing(true)
        HUD.show(HUDContentType.label("Get Video with key :\(tfSearch.text!)"))
        get50Video { videos in
            self.listVideo = videos.filter({ _video -> Bool in
                return _video.id != nil
            })
            
            HUD.hide()
        }
    }
    
    @IBAction func btnResetMyVideo() {
        self.listMyVideo.forEach { _video in
            _video.isSelected = false
        }
        self.listMyVideoSelected = []
        tbVideo.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    @IBAction func btnLogout() {
        GIDSignIn.sharedInstance().signOut()
    }
    
    func getVideo(url: String, param: [String: Any], completion: @escaping (_ listVideo: [Video])-> Void) {
        
        let request = Alamofire.request(url, method: .get, parameters: param)
        request.responseJSON { response in
            guard let data = response.data else { return }
            var newListVideo = [Video]()
            //
            let json = JSON(data)
            if let listJson = json["items"].array {
                for _jsonVideo in listJson {
                    let titleVideo = _jsonVideo["snippet"]["title"].string
                    let urlVideo = _jsonVideo["snippet"]["thumbnails"]["default"]["url"].string
                    let idVideo = _jsonVideo["id"]["videoId"].string
                    newListVideo.append(Video(id: idVideo, title: titleVideo, url: urlVideo))
                    
                }
            }
            
            completion(newListVideo)
        }
    }
    
    func get50Video(completion: @escaping (_ listVideo: [Video])-> Void) {
        let query = tfSearch.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: "+").replacingOccurrences(of: " ", with: "+")
        
        var newParam = rootParam
        newParam["q"] = query
        
        self.getVideo(url: urlSearch, param: newParam) { videos in
            completion(videos)
        }
    }
    
    func getMyVideo(completion: @escaping (_ listVideo: [Video])-> Void) {
        urlMySearch = urlMySearch.replacingOccurrences(of: "{id}", with: myChannelID)
        self.getVideo(url: urlMySearch, param: [:]) { videos in
            completion(videos)
        }
    }
}

// MARK: google
extension ViewController:  GIDSignInDelegate, GIDSignInUIDelegate {
    // delegate google
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        //          GIDSignIn.sharedInstance().signOut()
        if let error = error {
            PopUpHelper.showMessage(message: error.localizedDescription,controller: self)
            self.service.authorizer = nil
        } else {
            self.signInButton.isHidden = true
            self.service.authorizer = user.authentication.fetcherAuthorizer()
        }
    }
}

// MARK: TABLE
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func configureTable() {
        tbVideo.register(UINib(nibName: "VideoCell", bundle: nil), forCellReuseIdentifier: "cellId")
        tbVideo.delegate = self
        tbVideo.dataSource = self
        
        tbVideo.separatorStyle = .none
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 1 ? listVideo.count: listMyVideo.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tbVideo.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! VideoCell
        if indexPath.section == 1 {
            cell.video = self.listVideo[indexPath.item]
        } else {
            cell.video = self.listMyVideo[indexPath.item]
        }
        
        cell.lbTitle.text = "\(indexPath.item +  1). \(cell.lbTitle.text!)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemSelected = indexPath.section == 1 ? listVideo[indexPath.item]: listMyVideo[indexPath.item]
        itemSelected.isSelected = !itemSelected.isSelected
        tbVideo.reloadRows(at: [indexPath], with: .automatic)
        
        if indexPath.section == 1 {
            listVideoSelected = self.listVideo.filter({ video -> Bool in
                return video.isSelected == true
            })
        } else {
            
            if !checkContaint(video: itemSelected) {
                self.listMyVideoSelected.append(itemSelected)
            } else {
                self.listMyVideoSelected.remove(at: indexOf(video: itemSelected))
            }
        }
    }
    
    func checkContaint(video: Video) -> Bool {
        let containt =  self.listMyVideoSelected.contains { _video -> Bool in
            return _video.id == video.id
        }
        
        return containt
    }
    
    func indexOf(video: Video) -> Int {
        for (index, _video) in self.listMyVideoSelected.enumerated() {
            if video.id == _video.id {
                return index
            }
        }
        
        return -1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.backgroundColor = .gray
        
        if section == 0 {
            label.text = "My Video"
        } else {
            label.text = "Other Video"
        }
        
        return label
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
}
