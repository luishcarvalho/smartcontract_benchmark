pragma solidity ^0.4.0;








contract ProjectKudos {


    uint KUDOS_LIMIT_JUDGE = 1000;


    uint KUDOS_LIMIT_USER  = 10;



    enum GrantReason {
        Facebook,
        Twitter,
        Fake
    }


    struct ProjectInfo {
        mapping(address => uint) kudosByUser;
        uint kudosTotal;
    }


    struct UserInfo {
        uint kudosLimit;
        uint kudosGiven;
        bool isJudge;
        mapping(uint => bool) grant;
    }



    struct UserIndex {
        bytes32[] projects;
        uint[] kudos;
        mapping(bytes32 => uint) kudosIdx;
    }


    struct VotePeriod {
        uint start;
        uint end;
    }


    address owner;


    VotePeriod votePeriod;


    mapping(address => UserInfo) users;



    mapping(address => UserIndex) usersIndex;


    mapping(bytes32 => ProjectInfo) projects;


    event Vote(

        address indexed voter,

        bytes32 indexed projectCode,

        uint indexed count
    );





    function ProjectKudos() {

        owner = msg.sender;

        votePeriod = VotePeriod(
            1479996000,
            1482415200
        );
    }








    function register(address userAddres, bool isJudge) onlyOwner {

        UserInfo user = users[userAddres];

        if (user.kudosLimit > 0) throw;

        if (isJudge)
            user.kudosLimit = KUDOS_LIMIT_JUDGE;
        else
            user.kudosLimit = KUDOS_LIMIT_USER;

        user.isJudge = isJudge;

        users[userAddres] = user;
    }









    function giveKudos(string projectCode, uint kudos) duringVote {

        UserInfo giver = users[msg.sender];

        if (giver.kudosGiven + kudos > giver.kudosLimit) throw;

        bytes32 code = strToBytes(projectCode);
        ProjectInfo project = projects[code];

        giver.kudosGiven += kudos;
        project.kudosTotal += kudos;
        project.kudosByUser[msg.sender] += kudos;


        updateUsersIndex(code, project.kudosByUser[msg.sender]);

        Vote(msg.sender, sha3(projectCode), kudos);
    }










    function grantKudos(address userToGrant, uint reason) onlyOwner {

        UserInfo user = users[userToGrant];

        GrantReason grantReason = grantUintToReason(reason);

        if (grantReason != GrantReason.Facebook &&
            grantReason != GrantReason.Twitter) throw;




        if (user.isJudge) throw;


        if (user.grant[reason]) throw;


        user.kudosLimit += 100;


        user.grant[reason] = true;
    }













    function getProjectKudos(string projectCode) constant returns(uint) {
        bytes32 code = strToBytes(projectCode);
        ProjectInfo project = projects[code];
        return project.kudosTotal;
    }










    function getProjectKudosByUsers(string projectCode, address[] users) constant returns(uint[]) {
        bytes32 code = strToBytes(projectCode);
        ProjectInfo project = projects[code];
        mapping(address => uint) kudosByUser = project.kudosByUser;
        uint[] memory userKudos = new uint[](users.length);
        for (uint i = 0; i < users.length; i++) {
            userKudos[i] = kudosByUser[users[i]];
       }

       return userKudos;
    }










    function getKudosPerProject(address giver) constant returns (bytes32[] projects, uint[] kudos) {
        UserIndex idx = usersIndex[giver];
        projects = idx.projects;
        kudos = idx.kudos;
    }







    function getKudosLeft(address addr) constant returns(uint) {
        UserInfo user = users[addr];
        return user.kudosLimit - user.kudosGiven;
    }







    function getKudosGiven(address addr) constant returns(uint) {
        UserInfo user = users[addr];
        return user.kudosGiven;
    }












    function updateUsersIndex(bytes32 code, uint kudos) private {

        UserIndex idx = usersIndex[msg.sender];
        uint i = idx.kudosIdx[code];


        if (i == 0) {
            i = idx.projects.length + 1;
            idx.projects.length += 1;
            idx.kudos.length += 1;
            idx.projects[i - 1] = code;
            idx.kudosIdx[code] = i;
        }

        idx.kudos[i - 1] = kudos;
    }







    function grantUintToReason(uint reason) private returns (GrantReason result) {
        if (reason == 0)  return GrantReason.Facebook;
        if (reason == 1)  return GrantReason.Twitter;
        return GrantReason.Fake;
    }







    function grantReasonToUint(GrantReason reason) private returns (uint result) {
        if (reason == GrantReason.Facebook) return 0;
        if (reason == GrantReason.Twitter)  return 1;
        return 3;
    }









    function strToBytes(string str) private returns (bytes32 ret) {

        if (bytes(str).length > 32) throw;

        assembly {
            ret := mload(add(str, 32))
        }
    }









    modifier duringVote() {
        if (now < votePeriod.start) throw;
        if (now >= votePeriod.end) throw;
        _;
    }




    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }
}
