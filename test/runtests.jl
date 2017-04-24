using Base.Test
using Devices
using Unitful
import Unitful: s, DimensionError
import Clipper
import ForwardDiff

const pm2μm = Devices.PreferMicrons.pm
const pm = pm2μm
const nm2μm = Devices.PreferMicrons.nm
const nm = nm2μm
const μm2μm = Devices.PreferMicrons.μm
const μm = μm2μm
const mm2μm = Devices.PreferMicrons.mm
const mm = mm2μm
const cm2μm = Devices.PreferMicrons.cm
const m2μm = Devices.PreferMicrons.m
const m = m2μm

const nm2nm = Devices.PreferNanometers.nm
const μm2nm = Devices.PreferNanometers.μm
const cm2nm = Devices.PreferNanometers.cm
const m2nm = Devices.PreferNanometers.m

p(x,y) = Point(x,y)

@testset "Points" begin
    @testset "> Point constructors" begin
        @test_throws ErrorException Point(2,3m2μm)
        @test_throws ErrorException Point(2s,3s)    # has to be a length
        @test typeof(Point(2,3)) == Point{Int}
        @test typeof(Point(2,3.)) == Point{Float64}
        @test typeof(Point(2.,3)) == Point{Float64}
        @test typeof(Point(2m2μm,3.0m2μm)) == Point{typeof(3.0m2μm)}
        @test typeof(Point(2m2μm,3cm2μm)) == Point{typeof(2μm2μm//1)}
        @test typeof(Point(2.0m2μm,3cm2μm)) == Point{typeof(2.0μm2μm)}
        @test typeof(Point(2m2nm,3.0m2nm)) == Point{typeof(3.0m2nm)}
        @test typeof(Point(2m2nm,3cm2nm)) == Point{typeof(2nm2nm//1)}
        @test typeof(Point(2.0m2nm,3cm2nm)) == Point{typeof(2.0nm2nm)}
        @test typeof(Point(1.0/μm2μm, 1.0/nm2μm)) == Point{typeof(1.0/μm2μm)}
        @test typeof(Point(1.0/μm2nm, 1.0/nm2nm)) == Point{typeof(1.0/nm2nm)}
    end

    @testset "> Point arithmetic" begin
        @test Point(2,3) + Point(4,5) === Point(6,8)
        @test Point(1,0) - Point(0,1) === Point(1,-1)
        @test Point(3,3)/3 === Point(1.0,1.0)
        @test Point(1,1)*3 === Point(3,3)
        @test 3*Point(1,1) === Point(3,3)
        @test Point(2m2μm,3m2μm) + Point(4m2μm,5m2μm) === Point(6m2μm,8m2μm)
        @test Point(2m2μm,3m2μm) + Point(4cm2μm,5cm2μm) ===
            Point(2040000μm2μm//1,3050000μm2μm//1)
        @test Point(2.0m2μm,3m2μm) + Point(4cm2μm,5cm2μm) ===
            Point(2040000.0μm2μm,3050000.0μm2μm)
        @test Point(2m2nm,3m2nm) + Point(4m2nm,5m2nm) === Point(6m2nm,8m2nm)
        @test Point(2m2nm,3m2nm) + Point(4cm2nm,5cm2nm) ===
            Point(2040000000nm2nm//1,3050000000nm2nm//1)
        @test Point(2.0m2nm,3m2nm) + Point(4cm2nm,5cm2nm) ===
            Point(2040000000.0nm2nm,3050000000.0nm2nm)
    end

    @testset "> Point array arithmetic" begin
        @test [Point(1,2), Point(3,4)] .+ Point(1,1) == [Point(2,3), Point(4,5)]
        @test Point(1,1) .+ [Point(1,2), Point(3,4)] == [Point(2,3), Point(4,5)]
        @test [Point(1,2), Point(3,4)] + [Point(1,1), Point(-1,2)] ==
            [Point(2,3), Point(2,6)]

        @test [Point(1,2), Point(3,4)] .- Point(1,1) == [Point(0,1), Point(2,3)]
        @test Point(1,1) .- [Point(1,2), Point(2,3)] == [Point(0,-1), Point(-1,-2)]
        @test [Point(2,3)] - [Point(1,3)] == [Point(1,0)]
        if VERSION < v"0.6.0-pre"
            @test_throws ErrorException Point(1,2) - [Point(1,0)]
            @test_throws ErrorException [Point(2,3)] - Point(1,0)
            @test_throws ErrorException Point(1,2) + [Point(3,4)]
            @test_throws ErrorException [Point(1,2)] + Point(3,4)
        else
            @test_throws DimensionMismatch Point(1,2) - [Point(1,0)]
            @test_throws DimensionMismatch [Point(2,3)] - Point(1,0)
            @test_throws DimensionMismatch Point(1,2) + [Point(3,4)]
            @test_throws DimensionMismatch [Point(1,2)] + Point(3,4)
        end

        @test [Point(1,3)] .* 3 == [Point(3,9)]
        @test [Point(1,3)] * 3 == [Point(3,9)]
        @test 3 .* [Point(1,3)] == [Point(3,9)]
        @test 3 * [Point(1,3)] == [Point(3,9)]

        @test [Point(1m2μm,2m2μm)] + [Point(1cm2μm,2cm2μm)] ==
            [Point(101000000μm2μm//100, 202000000μm2μm//100)]
        @test [Point(1m2μm,2m2μm)] .+ Point(1cm2μm,2cm2μm) ==
            [Point(101000000μm2μm//100, 202000000μm2μm//100)]
        @test [Point(1m2μm,2m2μm)] - [Point(1cm2μm,2cm2μm)] ==
            [Point(99000000μm2μm//100, 198000000μm2μm//100)]
        @test [Point(1m2μm,2m2μm)] .- Point(1cm2μm,2cm2μm) ==
            [Point(99000000μm2μm//100, 198000000μm2μm//100)]

        @test [Point(1m2nm,2m2nm)] + [Point(1cm2nm,2cm2nm)] ==
            [Point(101000000000nm2nm//100, 202000000000nm2nm//100)]
        @test [Point(1m2nm,2m2nm)] .+ Point(1cm2nm,2cm2nm) ==
            [Point(101000000000nm2nm//100, 202000000000nm2nm//100)]
        @test [Point(1m2nm,2m2nm)] - [Point(1cm2nm,2cm2nm)] ==
            [Point(99000000000nm2nm//100, 198000000000nm2nm//100)]
        @test [Point(1m2nm,2m2nm)] .- Point(1cm2nm,2cm2nm) ==
            [Point(99000000000nm2nm//100, 198000000000nm2nm//100)]
    end

    @testset "> Point accessors" begin
        @test getx(Point(1,2)) == 1
        @test gety(Point(1,2)) == 2
    end

    @testset "> Point conversion" begin
        @test [Point(1,3), Point(2,4)] .* m2μm == [Point(1m2μm,3m2μm), Point(2m2μm,4m2μm)]
        @test convert(Point{Float64}, Clipper.IntPoint(1,2)) == Point(1.,2.)
        @test convert(Point{Int}, Clipper.IntPoint(1,2)) == Point(1,2)
    end
end

@testset "Polygon basics" begin
    @testset "> Rectangle construction" begin
        # lower-left and upper-right constructor
        r = Rectangle(Point(1,2), Point(2,0))
        @test typeof(r) == Rectangle{Int}
        @test r.ll == Point(1,0)
        @test r.ur == Point(2,2)

        # with units
        # @test typeof(Rectangle(Point(1m,2cm), Point(3nm,4μm))) ==
            # Rectangle{typeof(1ru//1)} #TODO: uncomment once Julia #18465 is fixed

        # width and height constructor
        @test typeof(Rectangle(1,2)) == Rectangle{Int}
        @test typeof(Rectangle(1.0,2)) == Rectangle{Float64}
        @test typeof(Rectangle(1.0m2μm,2.0μm2μm)) == Rectangle{typeof(1.0*μm2μm)}
    end

    @testset "> Polygon construction" begin
        @test_throws ErrorException Polygon(Point(1,2), Point(3,5), Point(4cm2μm,7cm2μm))
    end

    @testset "> Rectangle methods" begin
        # width and height
        @test width(Rectangle(1,2)) === 1
        @test height(Rectangle(1,2)) === 2
        @test width(Rectangle(1m,2m)) === 1m
        @test height(Rectangle(1m,2m)) === 2m

        # propriety
        @test Rectangle(Point(3,3),Point(0,0)) ==
            Rectangle(Point(0,0), Point(3,3))
        @test isproper(Rectangle(3,3))
        @test !isproper(Rectangle(0,0))

        # centering
        @test_throws InexactError centered!(Rectangle(1,1))
        @test_throws InexactError centered!(Rectangle(1m,1m))
        @test centered(Rectangle(1,1)) ==
            Rectangle(Point(-0.5,-0.5), Point(0.5,0.5))

        # Rectangle equality
        @test Rectangle(1,2) == Rectangle(1,2)
        @test Rectangle(1,2) ≈ Rectangle(1,2)

        # Rectangle bounds
        @test bounds(Rectangle(1,2)) == Rectangle(1,2)
    end

    @testset "> Polygon methods" begin
        pfloat = Polygon(Point(0.0m, 0.0m),
                         Point(1.0m, 0.0m),
                         Point(0.0m, 1.0m))
        # Polygon equality
        @test pfloat == Polygon(Point(0.0m, 0.0m),
                         Point(1.0m, 0.0m),
                         Point(0.0m, 1.0m))
        @test pfloat ≈ Polygon(Point(0.0m, 0.0m),
                         Point(1.0m, 0.0m),
                         Point(0.0m, 1.0m))

        # Bounds
        @test bounds(pfloat) ≈ Rectangle(1m,1m)
    end
end

@testset "Polygon coordinate transformations" begin
    pfloat = Polygon(Point(0.0m, 0.0m),
                     Point(1.0m, 0.0m),
                     Point(0.0m, 1.0m))
    pint = Polygon(Point(0m,0m),
                   Point(1m,0m),
                   Point(0m,1m))
    rfloat = Rectangle(1.0m,1.0m)
    rint = Rectangle(1m,1m)
    rinttr = Rectangle(Point(1m,2m), Point(2m,3m))
    pfloatrot = Polygon(Point(0.0m, 0.0m),
                        Point(0.0m, 1.0m),
                        Point(-1.0m, 0.0m))
    pfloattr = Polygon(Point(1.0m, 2.0m),
                       Point(2.0m, 2.0m),
                       Point(1.0m, 3.0m))
    rotDeg = Rotation(90°)
    rotRad = Rotation(π/2*rad)
    rotFlt = Rotation(π/2)
    trU = Translation(1m, 2m)
    @test rotDeg(pfloat) ≈ pfloatrot
    @test rotRad(pfloat) ≈ pfloatrot
    @test rotFlt(pfloat) ≈ pfloatrot
    @test rotDeg(pint) ≈ pfloatrot
    @test rotRad(pint) ≈ pfloatrot
    @test rotFlt(pint) ≈ pfloatrot
    @test trU(pfloat) ≈ pfloattr
    @test trU(pint) ≈ pfloattr
    @test trU(rint) == rinttr
    @test trU(rfloat) == rinttr
end

@testset "Polygon clipping" begin
    @testset "> Clipping individuals w/o units" begin
        # Rectangle{Int}, Rectangle{Int} clipping
        r1 = Rectangle(2,2)
        r2 = Rectangle(1,2)
        @test clip(Clipper.ClipTypeDifference, r1, r2)[1] ==
            Polygon(Point{Int}[p(2,2),p(1,2),p(1,0),p(2,0)])
        @test typeof(clip(Clipper.ClipTypeDifference, r1, r2)[1]) ==
            Polygon{Int}

        # Rectangle{Int}, Polygon{Int} clipping
        p2 = Polygon(Point{Int}[p(0,0), p(1,0), p(1,2), p(0,2)])
        @test clip(Clipper.ClipTypeDifference, r1, p2)[1] ==
            Polygon(Point{Int}[p(2,2),p(1,2),p(1,0),p(2,0)])
        @test typeof(clip(Clipper.ClipTypeDifference, r1, p2)[1]) ==
            Polygon{Int}

        # Polygon{Int}, Polygon{Int} clipping
        p1 = Polygon(Point{Int}[p(0,0), p(2,0), p(2,2), p(0,2)])
        @test clip(Clipper.ClipTypeDifference, p1, p2)[1] ==
            Polygon(Point{Int}[p(2,2), p(1,2), p(1,0), p(2,0)])
        @test typeof(clip(Clipper.ClipTypeDifference, p1, p2)[1]) ==
            Polygon{Int}

        # Rectangle{Float64}, Rectangle{Float64} clipping
        r1 = Rectangle(2.0,2.0)
        r2 = Rectangle(1.0,2.0)
        @test clip(Clipper.ClipTypeDifference, r1, r2)[1] ==
            Polygon(Point{Float64}[p(2.0,2.0), p(1.0,2.0), p(1.0,0.0), p(2.0,0.0)])
        @test typeof(clip(Clipper.ClipTypeDifference, r1, r2)[1]) ==
            Polygon{Float64}

        # Rectangle{Float64}, Polygon{Float64} clipping
        p2 = Polygon(Point{Float64}[p(0,0), p(1,0), p(1,2), p(0,2)])
        @test clip(Clipper.ClipTypeDifference, r1, p2)[1] ==
            Polygon(Point{Float64}[p(2,2), p(1,2), p(1,0), p(2,0)])
        @test typeof(clip(Clipper.ClipTypeDifference, r1, p2)[1]) ==
            Polygon{Float64}

        # Polygon{Float64}, Polygon{Float64} clipping
        p1 = Polygon(Point{Float64}[p(0,0), p(2,0), p(2,2), p(0,2)])
        @test clip(Clipper.ClipTypeDifference, p1, p2)[1] ==
            Polygon(Point{Float64}[p(2,2), p(1,2), p(1,0), p(2,0)])
        @test typeof(clip(Clipper.ClipTypeDifference, p1, p2)[1]) ==
            Polygon{Float64}

        # Test a case where the AbstractPolygon subtypes and numeric types are mixed
        # Rectangle{Int}, Polygon{Float64} clipping
        r2 = Rectangle(1,2)
        @test clip(Clipper.ClipTypeDifference, p1, r2)[1] ==
            Polygon(Point{Float64}[p(2,2), p(1,2), p(1,0), p(2,0)])
        @test typeof(clip(Clipper.ClipTypeDifference, p1, r2)[1]) ==
            Polygon{Float64}
    end

    @testset "> Clipping individuals w/units" begin
        # Rectangle{typeof(1μm)}, Rectangle{typeof(1μm)} clipping
        r1 = Rectangle(2μm,2μm)
        r2 = Rectangle(1μm,2μm)
        @test clip(Clipper.ClipTypeDifference, r1, r2)[1] ==
            Polygon(Point{typeof(1μm)}[p(2μm,2μm), p(1μm,2μm), p(1μm,0μm), p(2μm,0μm)])
        @test typeof(clip(Clipper.ClipTypeDifference, r1, r2)[1]) ==
            Polygon{typeof(1μm)}

        r1 = Rectangle(2.0μm,2.0μm)
        r2 = Rectangle(1.0μm,2.0μm)
        @test clip(Clipper.ClipTypeDifference, r1, r2)[1] ==
            Polygon(Point{typeof(1.0μm)}[p(2μm,2μm), p(1μm,2μm), p(1μm,0μm), p(2μm,0μm)])
        @test typeof(clip(Clipper.ClipTypeDifference, r1, r2)[1]) ==
            Polygon{typeof(1.0μm)}

        # MIXED UNITS do not behave ideally yet.
    end

    @testset "> Clipping arrays w/o units" begin
        r1 = Rectangle(2,2)
        s = [r1, r1+Point(0,4), r1+Point(0,8)]
        c = [Rectangle(1,10)]
        r = clip(Clipper.ClipTypeDifference, s, c)
        @test Polygon(Point{Int}[p(2,2),p(1,2),p(1,0),p(2,0)]) in r
        @test Polygon(Point{Int}[p(2,6),p(1,6),p(1,4),p(2,4)]) in r
        @test Polygon(Point{Int}[p(2,10),p(1,10),p(1,8),p(2,8)]) in r
        @test length(r) == 3
    end
end

@testset "Polygon offsetting" begin
    r = Rectangle(1, 1)
    @test offset(r, 1)[1] ==
        Polygon([p(2,2), p(-1,2), p(-1,-1), p(2,-1)])
    @test_throws DimensionError offset(r,1μm)

    r = Rectangle(1.0, 1.0)
    @test offset(r, 0.5)[1] ==
        Polygon([p(1.5, 1.5), p(-0.5, 1.5), p(-0.5, -0.5), p(1.5, -0.5)])
    @test_throws DimensionError offset(r, 0.5μm)

    r = Rectangle(1μm, 1μm)
    @test_throws DimensionError offset(r, 1)
    @test offset(r, 1μm)[1] == Polygon(
        [p(2μm, 2μm), p(-1μm, 2μm), p(-1μm, -1μm), p(2μm, -1μm)])
    @test offset(r, 5000nm)[1] == Polygon(
        [p(6μm, 6μm), p(-5μm, 6μm), p(-5μm, -5μm), p(6μm, -5μm)])

    r = Rectangle(1.0μm, 1.0μm)
    @test_throws DimensionError offset(r, 1.0)
    @test offset(r, 50nm)[1] ≈ Polygon(
        [p(1.05μm,1.05μm), p(-0.05μm,1.05μm), p(-0.05μm,-0.05μm), p(1.05μm,-0.05μm)])
end

@testset "Polygon rendering" begin
    @testset "Rectangle rendering" begin
        c3 = Cell("c3")
        r = Rectangle(5,10)
        @test_throws Unitful.DimensionError render!(c3, Rectangle(5m,10m))
    end
    #
    # @testset "Polygon rendering" begin
    #
    # end
end

@testset "Cell methods" begin
    # Setup nested cell refs
    c = Cell("main")
    c2 = Cell("c2")
    c3 = Cell("c3")
    r = Rectangle(5,10)
    render!(c3, r)
    c2ref = CellReference(c2, Point(-10.0,0.0); mag=1.0, rot=180°)
    @test c2ref.cell === c2
    c3ref = CellReference(c3, Point(10.0,0.0); mag=2.0, rot=90°)
    push!(c.refs, c2ref)
    push!(c2.refs, c3ref)
    tr = transform(c,c3ref)

    # Test cell transformations
    @test tr(Point(1,1)) ≈ Point(-18.0,-2.0)
    @test c["c2"]["c3"] == c3ref
    c′ = c + Point(10.0,10.0)
    c2ref′ = c2ref + Point(10.,10.)

    # Test bounds with cell refs
    @test bounds(c3) == r
    @test bounds(c2) == bounds(c3ref)
    @test bounds(c) == bounds(c2ref)
    @test bounds(c′) ≈ (bounds(c) + Point(10.0,10.0))
    @test bounds(c2ref′) ≈ (bounds(c2ref) + Point(10.,10.))

    # Test `flatten!` when encountering a CellReference
    flatten!(c)
    @test bounds(c) == bounds(c2ref)

    # More setup
    c = Cell("main")
    c2 = Cell("rect")
    render!(c2, Rectangle(5,5))
    arr = CellArray(c2, Point(0,0); dc=Point(10,0), dr=Point(0,10),
        ncols=10, nrows=10)
    @test arr.cell === c2
    push!(c.refs, arr)

    # Test bounds with cell arrays
    @test bounds(c) == Rectangle(95,95)

    # Test `flatten!` when encountering a CellArray
    flatten!(c)
    @test bounds(c) == Rectangle(95,95)

    # Test push! and pop!
end

@testset "Path basics" begin
    @testset "> Path constructors" begin
        @test typeof(Path()) == Path{Float64}
        @test typeof(Path(0,0)) == Path{Float64}
        @test typeof(Path(Point(0,0))) == Path{Float64}
        @test α0(Path()) == 0.0° == 0.0 == 0.0rad

        @test typeof(Path(0.0μm, 0.0μm)) == Path{typeof(1.0μm)}
        @test typeof(Path(0.0μm, 0.0nm)) == Path{typeof(1.0μm)}
        @test typeof(Path(0.0μm2nm, 0.0μm2nm)) == Path{typeof(1.0μm2nm)}
        @test typeof(Path(0.0μm2nm, 0.0nm2nm)) == Path{typeof(1.0nm2nm)}
        @test typeof(Path(0μm, 0μm)) == Path{typeof(1.0μm)}
        @test typeof(Path(0μm, 0nm)) == Path{typeof(1.0μm)}
        @test typeof(Path(0μm2nm, 0μm2nm)) == Path{typeof(1.0μm2nm)}
        @test typeof(Path(0μm2nm, 0nm2nm)) == Path{typeof(1.0nm2nm)}

        @test typeof(Path(Point(0.0μm, 0.0μm))) == Path{typeof(1.0μm)}
        @test typeof(Path(Point(0.0μm, 0.0nm))) == Path{typeof(1.0μm)}
        @test typeof(Path(Point(0.0μm2nm, 0.0μm2nm))) == Path{typeof(1.0μm2nm)}
        @test typeof(Path(Point(0.0μm2nm, 0.0nm2nm))) == Path{typeof(1.0nm2nm)}
        @test typeof(Path(Point(0μm, 0μm))) == Path{typeof(1.0μm)}
        @test typeof(Path(Point(0μm, 0nm))) == Path{typeof(1.0μm)}
        @test typeof(Path(Point(0μm2nm, 0μm2nm))) == Path{typeof(1.0μm2nm)}
        @test typeof(Path(Point(0μm2nm, 0nm2nm))) == Path{typeof(1.0nm2nm)}

        @test α0(Path(Point(0.0μm, 0.0μm); α0 = 90°)) == 90.0° == π*rad/2 == π/2
        @test α0(Path(Point(0.0μm, 0.0μm); α0 = π/2)) == 90.0° == π*rad/2 == π/2

        @test typeof(Path(μm)) == Path{typeof(1.0μm)}

        @test_throws DimensionError Path(0,0μm)
        @test_throws DimensionError Path(0nm,0)
    end

    @testset "> Path segments" begin
        pa = Path()
        @test_throws Unitful.DimensionError straight!(pa, 10.0μm)
        @test pathlength(pa) == 0.0
        straight!(pa, 10)
        @test pathlength(pa) == 10
        @test pathlength(segment(pa[1])) == 10
        turn!(pa, π/2, 5.0)
        @test pathlength(pa) == 10 + 5*π/2
        @test pathlength(segment(pa[2])) == 5π/2
        @test ForwardDiff.derivative(segment(pa[1]), 0.0) ≈ Point(1.0, 0.0)
        @test ForwardDiff.derivative(segment(pa[1]), 10.0) ≈ Point(1.0, 0.0)
        @test Devices.Paths.curvature(segment(pa[1]), 0.0) ≈ Point(0.0, 0.0)
        @test Devices.Paths.curvature(segment(pa[1]), 10.0) ≈ Point(0.0, 0.0)
        @test ForwardDiff.derivative(segment(pa[2]), 0.0) ≈ Point(1.0, 0.0)
        @test ForwardDiff.derivative(segment(pa[2]), 5π/2) ≈ Point(0.0, 1.0)
        @test Devices.Paths.curvature(segment(pa[2]), 0.0) ≈ Point(0.0, 0.2)
        @test Devices.Paths.curvature(segment(pa[2]), 5π/2) ≈ Point(-0.2, 0.0)

        pa = Path(μm)
        @test_throws Unitful.DimensionError straight!(pa, 10.0)
        @test pathlength(pa) == 0.0μm
        straight!(pa, 10μm)
        @test pathlength(pa) == 10μm
        @test pathlength(segment(pa[1])) == 10μm
        turn!(pa, π/2, 5.0μm)
        @test pathlength(pa) == (10 + 5*π/2)μm
        @test pathlength(segment(pa[2])) == (5π/2)μm
        @test ForwardDiff.derivative(segment(pa[1]), 0.0μm) ≈ Point(1.0, 0.0)
        @test ForwardDiff.derivative(segment(pa[1]), 10.0μm) ≈ Point(1.0, 0.0)
        @test Devices.Paths.curvature(segment(pa[1]), 0.0μm) ≈ Point(0.0/μm, 0.0/μm)
        @test Devices.Paths.curvature(segment(pa[1]), 10.0μm) ≈ Point(0.0/μm, 0.0/μm)
        @test ForwardDiff.derivative(segment(pa[2]), 0.0μm) ≈ Point(1.0, 0.0)
        @test ForwardDiff.derivative(segment(pa[2]), (5π/2)μm) ≈ Point(0.0, 1.0)
        @test Devices.Paths.curvature(segment(pa[2]), 0.0μm) ≈ Point(0.0/μm, 0.2/μm)
        @test Devices.Paths.curvature(segment(pa[2]), (5π/2)μm) ≈ Point(-0.2/μm, 0.0/μm)
    end

    @testset "> Path-based launchers" begin
        # w/o units
        pa = Path()
        sty = launch!(pa, trace1 = 4.2, gap1 = 3.8)
        @test isa(sty, Paths.CPW)
        @test length(pa) == 4
        @test Paths.gap(sty) === 3.8
        @test Paths.trace(sty) === 4.2

        # w/ units
        pa = Path(μm)
        sty = launch!(pa)
        @test Paths.gap(sty) === 6.0μm
        @test Paths.trace(sty) === 10.0μm

        pa = Path(nm)
        sty = launch!(pa)
        @test Paths.gap(sty) === 6000.0nm
        @test Paths.trace(sty) === 10000.0nm

        pa = Path(μm)
        sty = launch!(pa, trace1 = 4.2μm, gap1 = 3801nm)
        @test Paths.gap(sty) === 3.801μm
        @test Paths.trace(sty) === 4.2μm

        # test dimensionerrors
        pa = Path(μm)
        @test_throws DimensionError launch!(pa, trace1 = 3.0)
    end

    @testset "> CompoundSegment" begin
        pa = Path()
        straight!(pa, 200.0)
        turn!(pa, π/4, 50.0)
        straight!(pa, 200.0)
        segs = segment.(pa)
        f = Paths.param(segs)
        @test f(0.0) == p(0.0,0.0)
        @test f(1.0) == p(1.0,0.0)
        @test f(-1.0) == p(-1.0,0.0)
        @test f(200+50*π/4+199) ≈ p(200+50/sqrt(2)+199/sqrt(2), 50-50/sqrt(2)+199/sqrt(2))
        @test f(200+50*π/4+200) ≈ p(200+50/sqrt(2)+200/sqrt(2), 50-50/sqrt(2)+200/sqrt(2))
        @test f(200+50*π/4+201) ≈ p(200+50/sqrt(2)+201/sqrt(2), 50-50/sqrt(2)+201/sqrt(2))
        g = x->ForwardDiff.derivative(f, x)
        @test g(-1.0) ≈ g(0.0) ≈ g(1.0)
        @test g(200+50*π/4+199) ≈ g(200+50*π/4+200) ≈ g(200+50*π/4+201)
        simplify!(pa)

    end
end

@testset "Rendering unit tests" begin
    # Observe aliasing with rand_factor = 0.
    # Choosing large grid_step yields the minimum possible number of grid points (5).
    f = t->(2.0μm + 1.0μm*cos(2π*t/(50μm)))
    grid = Devices.adapted_grid(f, (0μm, 100μm), grid_step=1mm, rand_factor=0.0, max_change=1nm)
    @test grid == [0.0μm, 25μm, 50μm, 75μm, 100μm]
end

@testset "Style rendering" begin
    @testset "NoRender" begin
        c = Cell("main")
        pa = Path(α0=24.31°, style0=Paths.NoRender())
        straight!(pa, 21.2345)
        render!(c, pa)
        @test isempty(c.elements)
    end

    @testset "Decorations" begin
        csub = Cell{typeof(1.0nm)}("sub")
        render!(csub, centered!(Rectangle(10nm,10nm)))
        cref = CellReference(csub, Point(0.0μm, 0.0μm))

        c = Cell{typeof(1.0nm)}("main")
        pa = Path(μm, style0=Paths.NoRender())
        straight!(pa, 20.0μm)
        turn!(pa, π/2, 20.0μm)
        straight!(pa, 20.0μm)
        simplify!(pa)
        attach!(pa, cref, linspace(0μm, pathlength(pa), 3))
        render!(c,pa)

        @test isempty(c.elements)
        @test length(c.refs) == 3

        flatten!(c)

        @test isempty(c.refs)
        @test length(c.elements) == 3
        @test points(c.elements[1]) == Point{typeof(1.0nm)}[
            p(-5.0nm, -5.0nm),
            p(5.0nm,  -5.0nm),
            p(5.0nm,   5.0nm),
            p(-5.0nm,  5.0nm)
        ]
        @test points(c.elements[2]) == Point{typeof(1.0nm)}[
            p(34142.13562373095nm,  5850.793308457187nm),
            p(34149.206691542815nm, 5857.864376269053nm),
            p(34142.13562373095nm,  5864.9354440809175nm),
            p(34135.06455591909nm,  5857.864376269053nm)
        ]
        @test points(c.elements[3]) == Point{typeof(1.0nm)}[
            p(40005.0nm, 39995.0nm),
            p(40005.0nm, 40005.0nm),
            p(39995.0nm, 40005.0nm),
            p(39995.0nm, 39995.0nm)
        ]

        cref = CellReference(csub, Point(0.0μm, 10.0μm))
        c = Cell{typeof(1.0nm)}("main")
        setstyle!(pa[1], Paths.Trace(1μm))
        attach!(pa, cref, linspace(0μm, pathlength(pa), 3), location=-1)
        render!(c, pa)

        @test length(c.elements) == 1
        @test length(c.refs) == 3
        pop!(c.elements)
        flatten!(c)

        @test length(c.elements) == 3
        @test isempty(c.refs)
        @test points(c.elements[1]) == Point{typeof(1.0nm)}[
            p(-4.99999999999997nm, 10495.0nm),
            p(5.00000000000003nm,  10495.0nm),
            p(5.00000000000003nm,  10505.0nm),
            p(-4.99999999999997nm, 10505.0nm)
        ]
        @test points(c.elements[2]) == Point{typeof(1.0nm)}[
            p(26717.5144212722nm,   13275.414510915934nm),
            p(26724.585489084064nm, 13282.485578727801nm),
            p(26717.5144212722nm,   13289.556646539668nm),
            p(26710.443353460334nm, 13282.485578727801nm)
        ]
        @test points(c.elements[3]) == Point{typeof(1.0nm)}[
            p(29505.0nm, 39995.0nm),
            p(29505.0nm, 40005.0nm),
            p(29495.0nm, 40005.0nm),
            p(29495.0nm, 39995.0nm)
        ]
    end

    @testset "Straight, SimpleTrace" begin
        c = Cell("main")
        pa = Path(α0=12°)
        straight!(pa, 20.0)
        render!(c,pa)
        @test points(c.elements[1]) == Point{Float64}[
            p(-0.10395584540887967,  0.48907380036690284),
            p(19.458996169267234,    4.64730761672209),
            p(19.666907860084994,    3.6691600159882842),
            p(0.10395584540887973,  -0.4890738003669028)]

        c = Cell{typeof(1.0pm)}("main")
        pa = Path(μm, α0=12°)
        straight!(pa, 20000nm)
        render!(c,pa)
        @test points(c.elements[1]) == Point{typeof(1.0pm)}[
            p(-103955.84540887967pm,   489073.80036690284pm),
            p(1.9458996169267233e7pm,  4.64730761672209e6pm),
            p(1.9666907860084992e7pm,  3.6691600159882843e6pm),
            p(103955.84540887973pm,   -489073.8003669028pm)
        ]
    end

    @testset "Corner, SimpleTraceCorner" begin
        c = Cell("main")
        pa = Path()
        straight!(pa, 20.0)
        corner!(pa, π/2)
        straight!(pa, 20.0)
        render!(c, pa)

        @test length(c.elements) == 3
        @test points(c.elements[2]) == Point{Float64}[
            p(19.5,  0.5),
            p(19.5, -0.5),
            p(20.5, -0.5),
            p(20.5,  0.5)
        ]

        c = Cell{typeof(1.0μm)}("main")
        pa = Path(μm)
        straight!(pa, 20.0μm)
        corner!(pa, π/2)
        straight!(pa, 20.0μm)
        render!(c, pa)

        @test length(c.elements) == 3
        @test points(c.elements[2]) == Point{typeof(1.0μm)}[
            p(19.5μm,  0.5μm),
            p(19.5μm, -0.5μm),
            p(20.5μm, -0.5μm),
            p(20.5μm,  0.5μm)
        ]
    end

    @testset "Straight, GeneralTrace" begin
        c = Cell("main")
        pa = Path(style0=Paths.Trace(x->2.0*x))
        straight!(pa, 20.0)
        render!(c,pa)
    end

    @testset "Straight, SimpleCPW" begin
        c = Cell("main")
        pa = Path(α0=12°, style0=Paths.CPW(5.0,3.0))
        straight!(pa, 20.0)
        render!(c,pa)
        @test points(c.elements[1]) == Point{Float64}[
            p(-1.1435142994976764, 5.379811804035931),
            p(18.419437715178436,  9.538045620391118),
            p(19.043172787631715,  6.603602818189701),
            p(-0.5197792270443984, 2.4453690018345142)
        ]
        @test points(c.elements[2]) == Point{Float64}[
            p(0.5197792270443984, -2.4453690018345142),
            p(20.082731241720513,  1.7128648145206729),
            p(20.70646631417379,  -1.2215779876807442),
            p(1.1435142994976764, -5.379811804035931)
        ]

        c = Cell{typeof(1.0pm)}("main")
        pa = Path(μm, α0=12°, style0=Paths.CPW(5.0μm, 3000nm))
        straight!(pa, 20000nm)
        render!(c,pa)
        @test points(c.elements[1]) == Point{typeof(1.0pm)}[
            p(-1.1435142994976764pm, 5.379811804035931pm),
            p(18.419437715178436pm,  9.538045620391118pm),
            p(19.043172787631715pm,  6.603602818189701pm),
            p(-0.5197792270443984pm, 2.4453690018345142pm)
        ]*10^6
        @test points(c.elements[2]) == Point{typeof(1.0pm)}[
            p(0.5197792270443984pm, -2.4453690018345142pm),
            p(20.082731241720513pm,  1.7128648145206729pm),
            p(20.70646631417379pm,  -1.2215779876807442pm),
            p(1.1435142994976764pm, -5.379811804035931pm)
        ]*10^6
    end

    # @testset "Straight, GeneralCPW" begin
    #
    # end

    @testset "Turn, SimpleTrace" begin
        c = Cell("main")
        pa = Path()
        turn!(pa, π/2, 5.0)
        render!(c, pa)

        c = Cell{typeof(1.0nm)}("main")
        pa = Path(μm)
        turn!(pa, π/2, 20.0μm)
        render!(c, pa)
    end

    # @testset "Turn, GeneralTrace" begin
    #
    # end

    @testset "Turn, SimpleCPW" begin
        # Test low-res rendering for simplicity
        c = Cell("main")
        pa = Path()
        turn!(pa, π/2, 50.0, Paths.CPW(10.0,6.0))
        render!(c, pa, grid_step=500.0, max_change=90°)
        @test points(c.elements[1]) == Point{Float64}[
            p(6.79678973526781e-15,  11.0),
            p(14.147528631528852,    13.656535200670929),
            p(27.587463085789658,    22.433138000668393),
            p(36.518103010286126,    36.30955981240446),
            p(39.0,                  50.0),
            p(45.0,                  50.0),
            p(42.13627270417631,     34.203338245082065),
            p(31.83168817591114,     18.19208230846353),
            p(16.324071497917906,    8.06523292385107),
            p(6.429395695523605e-15, 5.0)
        ]
        @test points(c.elements[2]) == Point{Float64}[
            p(6.429395695523605e-15, -5.0),
            p(19.95164294189966,     -1.2536042041820252),
            p(38.90539665944695,     11.123656154788758),
            p(51.49988886065992,     30.69296896621141),
            p(55.0,                  50.0),
            p(61.0,                  50.0),
            p(57.1180585545501,      28.58674739888902),
            p(43.14962174956843,     6.882600462583895),
            p(22.128185808288713,    -6.844906481001884),
            p(6.79678973526781e-15,  -11.0)
        ]

        c = Cell{typeof(1.0nm)}("main")
        pa = Path(μm)
        turn!(pa, π/2, 50.0μm, Paths.CPW(10.0μm, 6.0μm))
        render!(c, pa, grid_step=500.0μm, max_change=90°)
        @test points(c.elements[1]) == Point{typeof(1.0nm)}[
            p(6.79678973526781e-12nm,  11000.0nm),
            p(14147.528631528852nm,    13656.535200670929nm),
            p(27587.46308578966nm,     22433.138000668394nm),
            p(36518.103010286126nm,    36309.559812404455nm),
            p(39000.0nm,               50000.0nm),
            p(45000.0nm,               50000.0nm),
            p(42136.27270417631nm,     34203.338245082065nm),
            p(31831.68817591114nm,     18192.08230846353nm),
            p(16324.071497917907nm,    8065.23292385107nm),
            p(6.429395695523605e-12nm, 5000.0nm)
        ]
        @test points(c.elements[2]) == Point{typeof(1.0nm)}[
            p(6.429395695523605e-12nm, -5000.0nm),
            p(19951.64294189966nm,     -1253.6042041820251nm),
            p(38905.39665944695nm,     11123.656154788758nm),
            p(51499.88886065992nm,     30692.96896621141nm),
            p(55000.0nm,               50000.0nm),
            p(61000.0nm,               50000.0nm),
            p(57118.0585545501nm,      28586.74739888902nm),
            p(43149.62174956843nm,     6882.600462583895nm),
            p(22128.185808288712nm,    -6844.906481001884nm),
            p(6.79678973526781e-12nm,  -11000.0nm)
        ]

    end

    @testset "CompoundSegment" begin
        # CompoundSegment, CompoundStyle should render as if the path wasn't simplified,
        # provided that's possible. This is done for rendering and filesize efficiency.
        c = Cell("main")
        pa = Path()
        straight!(pa, 20.0)
        straight!(pa, 30.0)
        simplify!(pa)
        render!(c, pa)
        @test points(c.elements[1]) ≈ [p(0, 0.5), p(20,0.5), p(20,-0.5), p(0, -0.5)]
        @test points(c.elements[2]) ≈ [p(20,0.5), p(50,0.5), p(50,-0.5), p(20,-0.5)]

        # OTOH, if we swap out the style, fall back to rendering using the CompoundSegment's
        # path function. In this case we just get one longer straight segment but in
        # general the path function can be complicated
        c = Cell("main")
        setstyle!(pa[1], Paths.Trace(1.0))
        render!(c, pa, grid_step = 50.0)
        @test points(c.elements[1]) ≈ [
            p(0,0.5),
            p(11.816454754947033,0.5),
            p(25.0118894196795,0.5),
            p(38.582915904525976,0.5),
            p(50.0,0.5),
            p(50.0,-0.5),
            p(38.582915904525976,-0.5),
            p(25.0118894196795,-0.5),
            p(11.816454754947033,-0.5),
            p(0,-0.5)
        ]
    end
end

@testset "Compound shapes" begin
    @testset "Checkerboard" begin
        c = Cell("main")
        checkerboard!(c, 20.0, 2, false, layer=0)
        @test length(c.refs) == 2
        flatten!(c)
        @test points(c.elements[1]) ≈ [
            p(0.0,0.0),
            p(20.0,0.0),
            p(20.0,20.0),
            p(0.0,20.0)
        ]
        @test points(c.elements[2]) ≈ [
            p(20.0,20.0),
            p(40.0,20.0),
            p(40.0,40.0),
            p(20.0,40.0)
        ]

        c = Cell("main", nm)
        checkerboard!(c, 20μm, 2, true, layer=0)
        @test length(c.refs) == 2
        flatten!(c)
        @test points(c.elements[1]) ≈ [
            p(0.0nm,20000.0nm),
            p(20000.0nm,20000.0nm),
            p(20000.0nm,40000.0nm),
            p(0.0nm,40000.0nm)
        ]
        @test points(c.elements[2]) ≈ [
            p(20000.0nm,0.0nm),
            p(40000.0nm,0.0nm),
            p(40000.0nm,20000.0nm),
            p(20000.0nm,20000.0nm)
        ]
    end

    @testset "Grating" begin
        c = Cell("main", nm)
        grating!(c, 100nm, 100nm, 20μm)
        flatten!(c)
        @test length(c.elements) == 100
        @test points(c.elements[1]) ≈ [
            p(0.0nm,0.0nm),
            p(100.0nm,0.0nm),
            p(100.0nm,20000.0nm),
            p(0.0nm,20000.0nm)
        ]
    end

    @testset "IDC" begin
        c = Cell("main", nm)
        interdigit!(c, 1μm, 10μm, 1μm, 1μm, 2, true)
        flatten!(c)
        @test length(c.elements) == 3
        @test points(c.elements[1]) ≈ [
            p(0.0nm,0.0nm),
            p(10000.0nm,0.0nm),
            p(10000.0nm,1000.0nm),
            p(0.0nm,1000.0nm)
        ]
        @test points(c.elements[2]) ≈ [
            p(0.0nm,4000.0nm),
            p(10000.0nm,4000.0nm),
            p(10000.0nm,5000.0nm),
            p(0.0nm,5000.0nm)
        ]
        @test points(c.elements[3]) ≈ [
            p(1000.0nm,2000.0nm),
            p(11000.0nm,2000.0nm),
            p(11000.0nm,3000.0nm),
            p(1000.0nm,3000.0nm)
        ]
    end
end

# TODO: How to test GDS import?
# TODO: How to test GDS export? diff with known good result files?
