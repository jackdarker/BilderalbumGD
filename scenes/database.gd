class_name TagDatabase extends Node

var db : SQLite = null
var db_name = "res://data/database"		#TODO res: is read only in release build !
const verbosity_level : int = SQLite.QUIET #SQLite.VERBOSE

#Note: items (capitals) returned by SELECT depend how the tables were initial defined, not on the query itself

func _ready():
	dbinit()
	_test1()

func dbinit():
	db = SQLite.new()
	db.path = db_name
	db.verbosity_level = verbosity_level
	# Open the database using the db_name found in the path variable
	db.open_db()
	var query 
	query = "CREATE TABLE IF NOT EXISTS Posts (
		postID INTEGER PRIMARY KEY AUTOINCREMENT, 
		boardID INTEGER NOT NULL,
		replyToID INTEGER,
		name TEXT NOT NULL,
		subject TEXT,
		dateTime TEXT,
		postText TEXT,
		fileName TEXT,
		posterID TEXT NOT NULL,
		fileExt TEXT
		)"
	db.query(query)
	query = "CREATE TABLE IF NOT EXISTS Boards (
		boardID INTEGER PRIMARY KEY AUTOINCREMENT, 
		boardName TEXT NOT NULL
		)"
	db.query(query)
	query = "CREATE TABLE IF NOT EXISTS PostTags (
		postID  INTEGER NOT NULL, 
		tagID  INTEGER NOT NULL, 
		PRIMARY KEY (postID,tagID) ON CONFLICT IGNORE
		)"
	db.query(query)
	query = "CREATE TABLE IF NOT EXISTS Tags (
		ID	INTEGER PRIMARY KEY AUTOINCREMENT,
		groupID	INTEGER,
		name	TEXT			
		)"
	db.query(query)
	query = "CREATE TABLE IF NOT EXISTS TagGroups (
		ID	INTEGER PRIMARY KEY AUTOINCREMENT,
		name	TEXT,
		color	TEXT,
		fgColor	TEXT,
		shape	TEXT			
		)"
	db.query(query)
	query="SELECT COUNT(*) AS CNTREC FROM pragma_table_info('TagGroups') WHERE name='fgColor'"
	db.query(query)
	if (db.query_result[0]["CNTREC"]<=0):
		query = "ALTER TABLE TagGroups ADD fgColor TEXT"
		db.query(query)
		query = "ALTER TABLE TagGroups ADD shape TEXT"
		db.query(query)

func _test1():
	var results
	var postid
	var tagid
	createTagGroup({"name":"aqua","color":"aqua","fgcolor":"white","shape":""});
	createTagGroup({"name":"gray","color":"gray","fgcolor":"white","shape":""});
	results = findTagGroups()
	
	tagid=createTag({"name":"new","groupID":1})
	createTag({"name":"old","groupID":2})
	
	#postid=createPost({"filename":"c:/temp/new","name":"new file"})
	#assignTagToPost(postid,[tagid])
	#results=findPost("c:/temp/new")
	#results=findPostByTag("new")
	results=getTagStatistic()
	pass
	
func createTagGroup(group:Dictionary)->int:
	if(!group.has("newname")):
		group["newname"]=group.name
	var rowID:int=-1
	var query	
	var selected_array : Array = db.select_rows("TagGroups", "name='"+group.name+"'", ["id"])
	if(selected_array.size()>0):
		query="Update TagGroups SET name='"+group.newname+"',Color='"+group.color+"',FGColor='"+group.fgcolor+"',Shape='"+group.shape+"' where (name='"+group.name+"')"
		db.query(query)
		rowID=selected_array[0]["ID"]
	else:
		query="Insert Into TagGroups (name,Color,FGColor,Shape) VALUES('"+group.newname+"','"+group.color+"','"+group.fgcolor+"','"+group.shape+"')"
		db.query(query)
		rowID = db.last_insert_rowid
	return(rowID)

#TODO	func deleteTagGroup():
#	delete group&Tags&Posttags?

func findTagGroups()->Array:
	var results : Array = db.select_rows("TagGroups", "", ["id","name","color","fgcolor","shape"])
	return(results);

func createTag(tag)->int:
	if(!tag.has("groupID")):
		tag["groupID"] = 1
	if(!tag.has("newname")):
		tag["newname"] = tag.name
	var query
	var rowID=-1
	var selected_array : Array = db.select_rows("Tags", "name='"+tag.name+"'", ["ID"])
	if(selected_array.size()>0):
		query= "Update Tags SET name='"+tag.newname+"', groupID="+str(tag.groupID)+" where (name='"+tag.name+"')"
		db.query(query)
		rowID=selected_array[0]["ID"]
	else:
		query="Insert Into Tags (name,GroupID) VALUES('"+tag.newname+"',"+str(tag.groupID)+")"
		db.query(query)
		rowID = db.last_insert_rowid
	return(rowID);


func deleteTag(tag):
	#todo only delete if no one uses it, maybe mark for deletion and hide ?
	db.query("Delete from PostTags where (tagID='"+tag.ID+"')")
	db.query("Delete from Tags where (name='"+tag.name+"')")

func findTags(exclude:Array[int])->Array:
	var _exclude:String=",".join(exclude.map(func(x):return(str(x))))
	var query = "SELECT Tags.id,Tags.name, TagGroups.ID as groupID, TagGroups.color, TagGroups.fgcolor, TagGroups.shape 
		FROM Tags left join TagGroups on Tags.GroupID=TagGroups.ID
		WHERE Tags.ID NOT IN("+_exclude+")"
	db.query(query)
	return(db.query_result)
	
func findPostTags(postId)->Array:
	var query = "SELECT Tags.id,Tags.name, TagGroups.ID as groupID, TagGroups.color, TagGroups.fgcolor, TagGroups.shape FROM Tags 
			inner join PostTags on Tags.ID=PostTags.tagId 
			left join TagGroups on Tags.GroupID=TagGroups.ID 
			WHERE PostTags.postID="+str(postId)
	db.query(query)
	return(db.query_result)

func createPost(post)->int:
	post["posterID"]="unknown"		#todo
	post["boardID"]=0
	var rowID=-1;
	var selected_array : Array = db.select_rows("Posts", "name='"+post.name+"'", ["postID"])
	var query
	if(selected_array.size()>0):
		query= "Update Posts Set boardId="+str(post.boardID)+",posterID='"+str(post.posterID)+"', fileName='"+post.filename+"', name='"+post.name+"' where (name='"+post.name+"')"
		db.query(query)
		rowID=selected_array[0]["postID"]
	else:
		query= "Insert Into Posts (boardID,posterID,fileName,name) VALUES("+str(post.boardID)+",'"+str(post.posterID)+"','"+post.filename+"','"+post.name+"')"
		db.query(query)
		rowID = db.last_insert_rowid
	return(rowID)
	
func getPost(postID)->Array:
	var results : Array = db.select_rows("Posts", "postID="+str(postID), ["boardID","postID","name","fileName"])
	return results

func assignTagToPost(postid:int,tagids:Array[int]):
	var ids:String = ", ".join(tagids)
	var query="Delete From PostTags Where postID="+str(postid)+" AND tagId NOT IN("+ids+")"
	db.query(query)
	
	for id in tagids:
		query = "Insert Into PostTags (postID,tagId) VALUES("+str(postid)+","+str(id)+")"
		db.query(query)

#relative path+name
func findPost(search)->Array:
	var results : Array = db.select_rows("Posts", "fileName='"+str(search)+"'", ["boardID","postID","name","fileName"])
	return results

#search doesnt support wildcards !
func findPostByTag(withTags:Array[String],withoutTags:Array[String])->Array:
	if(withTags.size()<=0):
		return []
	var	_in="'" + "','".join(withTags) + "'"	#  'green','red'
	var	_out="'" + "','".join(withoutTags) + "'"
	var query
	#select distinct Posts.postid,Posts.fileName from Posts 
		#inner join PostTags on Posts.postID=PostTags.postID 
		#inner join Tags on Tags.ID=PostTags.tagID
		#inner join ( 
			#select PostTags.postid  from PostTags
			#inner join Tags on Tags.ID=PostTags.tagID
			#where  Tags.name IN('old','new')
			#group by PostTags.postid
			#having count(*)=2
			#EXCEPT
			#select PostTags.postid  from PostTags
			#inner join Tags on Tags.ID=PostTags.tagID
			#where  Tags.name IN('new2')
			#group by PostTags.postid
			#having count(*)=1
		#) as t1 on Posts.postid=t1.postid
		
	query ="select distinct Posts.postid,Posts.fileName from Posts 
		inner join PostTags on Posts.postID=PostTags.postID 
		inner join Tags on Tags.ID=PostTags.tagID 
		inner join ( "
	if(withTags.size()>0):
		query+= "select PostTags.postid from PostTags
		inner join Tags on Tags.ID=PostTags.tagID
		where Tags.name IN("+_in+")
		group by PostTags.postid
		having count(*)="+str(withTags.size())
	if(withoutTags.size()>0):
		query+=" EXCEPT
			select PostTags.postid from PostTags
		inner join Tags on Tags.ID=PostTags.tagID
		where Tags.name IN("+_out+")
		group by PostTags.postid
		having count(*)="+str(withoutTags.size())
	query+=") as t1 on Posts.postid=t1.postid"
	db.query(query)
	return(db.query_result)

func getTagStatistic()->Array:
	var query = "SELECT Tags.id,max(Tags.Name) as name,count(Tags.ID) as count,max(TagGroups.Color) as color, max(TagGroups.FGColor) as fgcolor,max(TagGroups.Shape) as shape FROM Tags 
		inner join PostTags on Tags.ID=PostTags.tagId 
		left join TagGroups on Tags.GroupID=TagGroups.ID 
		Group by (Tags.ID) order by count desc "
	db.query(query)
	return(db.query_result)
