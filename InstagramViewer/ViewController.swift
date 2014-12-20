// ViewController.swift
//
// Copyright (c) 2014 Shintaro Kaneko
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

import Alamofire
import SwiftyJSON

struct Caption {
    var username: String?
    var text: String?
}

struct Media {
    var thumbnailURL: NSURL?
    var imageURL: NSURL?
    var caption: Caption?
}

class ViewController: UITableViewController {

    var mediaList: [Media] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        let urlString = "https://api.instagram.com/v1/media/popular"
        let param = ["client_id": "<#CLIENT-ID#>"]
        let req = request(.GET, urlString, parameters: param)
        //* with SwiftyJSON
        req.response { (request, response, responseData, error) -> Void in
            if error == nil {
                if let data = responseData as? NSData {
                    self.mediaList = []
                    let json = JSON(data: data)
                    if let array = json["data"].array {
                        for d in array {
                            var caption = Caption(
                                username: d["caption"]["from"]["username"].string,
                                text:     d["caption"]["text"].string
                            )
                            var media = Media(
                                thumbnailURL: d["images"]["thumbnail"]["url"].URL,
                                imageURL:     d["images"]["standard_resolution"]["url"].URL,
                                caption:      caption
                            )
                            self.mediaList.append(media)
                        }
                    }
                    self.tableView.reloadData()
                    self.tableView.setNeedsLayout()
                }
            }
        }
        //*/
        /* without SwiftyJSON
        req.responseJSON { (request, response, jsonData, error) -> Void in
            if error == nil {
                if let json = jsonData as? NSDictionary {
                    self.mediaList = []
                    if let array = json["data"] as? NSArray {
                        for d in array {
                            if let dict = d as? NSDictionary {
                                var caption = Caption(
                                    username: ((dict["caption"] as? NSDictionary)?["from"] as? NSDictionary)?["username"] as? NSString,
                                    text:     (dict["caption"] as? NSDictionary)?["text"] as NSString
                                )
                                var media = Media(
                                    thumbnailURL: NSURL(string: ((dict["images"] as? NSDictionary)?["thumbnail"] as? NSDictionary)?["url"] as NSString)!,
                                    imageURL:     NSURL(string: ((dict["images"] as? NSDictionary)?["standard_resolution"] as? NSDictionary)?["url"] as NSString)!,
                                    caption:      caption
                                )
                                self.mediaList.append(media)
                            }
                        }
                    }
                    self.tableView.reloadData()
                    self.tableView.setNeedsLayout()
                }
            }
        }
        */
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let media = self.mediaList[indexPath.row] as Media
                (segue.destinationViewController as DetailViewController).media = media
            }
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mediaList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        let media = self.mediaList[indexPath.row]
        cell.imageView!.image = nil
        cell.textLabel?.text = media.caption?.text
        cell.textLabel?.numberOfLines = 0
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let data = NSData(contentsOfURL: media.thumbnailURL!)
            dispatch_sync(dispatch_get_main_queue(), {
                cell.imageView!.image = UIImage(data: data!, scale: UIScreen.mainScreen().scale)
                cell.setNeedsLayout()
            })
        })
        return cell
    }


}

